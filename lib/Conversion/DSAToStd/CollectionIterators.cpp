#include "mlir/Dialect/DSA/IR/DSAOps.h"
#include "mlir/Dialect/DSA/IR/DSATypes.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/SCF/IR/SCF.h"

#include "mlir/Dialect/util/UtilOps.h"

#include "mlir/Conversion/DSAToStd/CollectionIteration.h"
#include <mlir/IR/Builders.h>
#include <mlir/IR/PatternMatch.h>
#include <mlir/Transforms/DialectConversion.h>

#include "runtime-defs/DataSourceIteration.h"
using namespace mlir;

class WhileIterator {
   protected:
   mlir::TypeConverter* typeConverter;
   MLIRContext* context;
   mlir::Location loc;
   WhileIterator(mlir::MLIRContext* context) : context(context), loc(mlir::UnknownLoc::get(context)) {}

   public:
   void setTypeConverter(TypeConverter* typeConverter) {
      WhileIterator::typeConverter = typeConverter;
   }
   void setLoc(mlir::Location loc) {
      this->loc = loc;
   }
   virtual Type iteratorType(OpBuilder& builder) = 0;
   virtual void init(OpBuilder& builder){};
   virtual Value iterator(OpBuilder& builder) = 0;
   virtual Value iteratorNext(OpBuilder& builder, Value iterator) = 0;
   virtual Value iteratorGetCurrentElement(OpBuilder& builder, Value iterator) = 0;
   virtual Value iteratorValid(OpBuilder& builder, Value iterator) = 0;
   virtual void iteratorFree(OpBuilder& builder, Value iterator){};
   virtual ~WhileIterator() {}
};
class ForIterator {
   protected:
   mlir::TypeConverter* typeConverter;
   MLIRContext* context;
   mlir::Location loc;
   mlir::Value len;
   ForIterator(mlir::MLIRContext* context) : context(context), loc(mlir::UnknownLoc::get(context)) {}

   public:
   void setLoc(mlir::Location loc) {
      this->loc = loc;
   }
   virtual void init(OpBuilder& builder){};
   virtual Value lower(OpBuilder& builder) {
      return builder.create<arith::ConstantIndexOp>(loc, 0);
   }

   virtual Value upper(OpBuilder& builder) {
      return len;
   }
   virtual Value step(OpBuilder& builder) {
      return builder.create<arith::ConstantIndexOp>(loc, 1);
   }
   virtual Value getElement(OpBuilder& builder, Value index) = 0;
   virtual ~ForIterator() {}
   void setTypeConverter(TypeConverter* typeConverter) {
      ForIterator::typeConverter = typeConverter;
   }
};
class TableIterator2 : public WhileIterator {
   Value tableInfo;
   mlir::dsa::RecordBatchType recordBatchType;

   public:
   TableIterator2(Value tableInfo, mlir::dsa::RecordBatchType recordBatchType) : WhileIterator(tableInfo.getContext()), tableInfo(tableInfo), recordBatchType(recordBatchType) {}

   virtual Type iteratorType(OpBuilder& builder) override {
      return mlir::util::RefType::get(builder.getContext(), IntegerType::get(builder.getContext(), 8));
   }

   virtual Value iterator(OpBuilder& builder) override {
      return tableInfo;
   }
   virtual Value iteratorNext(OpBuilder& builder, Value iterator) override {
      rt::DataSourceIteration::next(builder, loc)({iterator});
      return tableInfo;
   }
   virtual Value iteratorGetCurrentElement(OpBuilder& builder, Value iterator) override {
      mlir::Value recordBatchInfoPtr;
      {
         mlir::OpBuilder::InsertionGuard guard(builder);
         builder.setInsertionPointToStart(&iterator.getParentRegion()->getParentOfType<mlir::func::FuncOp>().getBody().front());
         recordBatchInfoPtr = builder.create<mlir::util::AllocaOp>(loc, mlir::util::RefType::get(builder.getContext(), typeConverter->convertType(recordBatchType)), mlir::Value());
      }
      rt::DataSourceIteration::access(builder, loc)({iterator, recordBatchInfoPtr});
      return builder.create<mlir::util::LoadOp>(loc, recordBatchInfoPtr, mlir::Value());
   }
   virtual Value iteratorValid(OpBuilder& builder, Value iterator) override {
      return rt::DataSourceIteration::isValid(builder, loc)({iterator})[0];
   }
   virtual void iteratorFree(OpBuilder& builder, Value iterator) override {
      rt::DataSourceIteration::end(builder, loc)({iterator});
   }
};

class RecordBatchIterator : public ForIterator {
   mlir::Value recordBatch;
   mlir::dsa::RecordBatchType recordBatchType;

   public:
   RecordBatchIterator(Value recordBatch, Type recordBatchType) : ForIterator(recordBatch.getContext()), recordBatch(recordBatch), recordBatchType(recordBatchType.cast<mlir::dsa::RecordBatchType>()) {
   }
   virtual Value upper(OpBuilder& builder) override {
      return builder.create<mlir::util::GetTupleOp>(loc, builder.getIndexType(), recordBatch, 0);
   }
   virtual Value getElement(OpBuilder& builder, Value index) override {
      return builder.create<mlir::util::PackOp>(loc, typeConverter->convertType(mlir::dsa::RecordType::get(builder.getContext(), recordBatchType.getRowType())), mlir::ValueRange({index, recordBatch}));
   }
};

class BufferIterator : public ForIterator {
   Value buffer;
   Value values;

   public:
   BufferIterator(Value buffer) : ForIterator(buffer.getContext()), buffer(buffer) {
   }
   virtual void init(OpBuilder& builder) override {
      values = builder.create<util::BufferGetRef>(loc, buffer.getType().cast<mlir::util::BufferType>().getElementType(), buffer);
      len = builder.create<util::BufferGetLen>(loc, mlir::IndexType::get(context), buffer);
   }
   virtual Value getElement(OpBuilder& builder, Value index) override {
      return builder.create<util::ArrayElementPtrOp>(loc, mlir::util::RefType::get(buffer.getContext(), values.getType().cast<mlir::util::RefType>().getElementType()), values, index);
   }
};

static std::vector<Value> remap(std::vector<Value> values, ConversionPatternRewriter& builder) {
   for (size_t i = 0; i < values.size(); i++) {
      values[i] = builder.getRemappedValue(values[i]);
   }
   return values;
}

class WhileIteratorIterationImpl : public mlir::dsa::CollectionIterationImpl {
   std::unique_ptr<WhileIterator> iterator;

   public:
   WhileIteratorIterationImpl(std::unique_ptr<WhileIterator> iterator) : iterator(std::move(iterator)) {
   }
   virtual std::vector<Value> implementLoop(mlir::Location loc, mlir::ValueRange iterArgs, mlir::TypeConverter& typeConverter, ConversionPatternRewriter& builder, ModuleOp parentModule, std::function<std::vector<Value>(std::function<Value(OpBuilder&)>, ValueRange, OpBuilder)> bodyBuilder) override {
      auto insertionPoint = builder.saveInsertionPoint();

      iterator->setTypeConverter(&typeConverter);
      iterator->init(builder);
      iterator->setLoc(loc);
      Type iteratorType = iterator->iteratorType(builder);
      Value initialIterator = iterator->iterator(builder);
      std::vector<Type> results = {typeConverter.convertType(iteratorType)};
      std::vector<Value> iterValues = {builder.getRemappedValue(initialIterator)};
      for (auto iterArg : iterArgs) {
         results.push_back(typeConverter.convertType(iterArg.getType()));
         iterValues.push_back(builder.getRemappedValue(iterArg));
      }
      auto whileOp = builder.create<mlir::scf::WhileOp>(loc, results, iterValues);
      Block* before = new Block;
      Block* after = new Block;
      whileOp.getBefore().push_back(before);
      whileOp.getAfter().push_back(after);
      for (auto t : results) {
         before->addArgument(t, loc);
         after->addArgument(t, loc);
      }

      builder.setInsertionPointToStart(&whileOp.getBefore().front());
      auto arg1 = whileOp.getBefore().front().getArgument(0);
      Value condition = iterator->iteratorValid(builder, arg1);
      builder.create<mlir::scf::ConditionOp>(loc, builder.getRemappedValue(condition), whileOp.getBefore().front().getArguments());
      builder.setInsertionPointToStart(&whileOp.getAfter().front());
      auto arg2 = whileOp.getAfter().front().getArgument(0);
      auto terminator = builder.create<mlir::dsa::YieldOp>(loc);
      builder.setInsertionPoint(terminator);
      std::vector<Value> bodyParams = {};
      auto additionalArgs = whileOp.getAfter().front().getArguments().drop_front();
      bodyParams.insert(bodyParams.end(), additionalArgs.begin(), additionalArgs.end());
      auto returnValues = bodyBuilder([&](mlir::OpBuilder& b) { return iterator->iteratorGetCurrentElement(b, arg2); }, bodyParams, builder);
      builder.setInsertionPoint(terminator);
      Value nextIterator = iterator->iteratorNext(builder, arg2);
      returnValues.insert(returnValues.begin(), nextIterator);
      builder.create<mlir::scf::YieldOp>(loc, remap(returnValues, builder));
      builder.eraseOp(terminator);
      Value finalIterator = whileOp.getResult(0);
      builder.restoreInsertionPoint(insertionPoint);
      iterator->iteratorFree(builder, finalIterator);
      auto loopResultValues = whileOp.getResults().drop_front();
      return std::vector<Value>(loopResultValues.begin(), loopResultValues.end());
   }
};
class ForIteratorIterationImpl : public mlir::dsa::CollectionIterationImpl {
   std::unique_ptr<ForIterator> iterator;

   public:
   ForIteratorIterationImpl(std::unique_ptr<ForIterator> iterator) : iterator(std::move(iterator)) {
   }
   virtual std::vector<Value> implementLoop(mlir::Location loc, mlir::ValueRange iterArgs, mlir::TypeConverter& typeConverter, ConversionPatternRewriter& builder, ModuleOp parentModule, std::function<std::vector<Value>(std::function<Value(OpBuilder&)>, ValueRange, OpBuilder)> bodyBuilder) override {
      return implementLoopSimple(loc, iterArgs, typeConverter, builder, bodyBuilder);
   }
   std::vector<Value> implementLoopSimple(mlir::Location loc, const ValueRange& iterArgs, TypeConverter& typeConverter, ConversionPatternRewriter& builder, std::function<std::vector<Value>(std::function<Value(OpBuilder&)>, ValueRange, OpBuilder)> bodyBuilder) {
      auto insertionPoint = builder.saveInsertionPoint();
      iterator->setTypeConverter(&typeConverter);
      iterator->init(builder);
      iterator->setLoc(loc);
      auto forOp = builder.create<scf::ForOp>(loc, iterator->lower(builder), iterator->upper(builder), iterator->step(builder), iterArgs.size() ? iterArgs : llvm::None);
      if (iterArgs.size()) {
         builder.setInsertionPointToStart(forOp.getBody());
         builder.create<scf::YieldOp>(loc);
      }
      Operation* terminator = forOp.getBody()->getTerminator();
      builder.setInsertionPointToStart(forOp.getBody());
      std::vector<Value> bodyArguments = {};

      bodyArguments.insert(bodyArguments.end(), forOp.getRegionIterArgs().begin(), forOp.getRegionIterArgs().end());
      Value element;
      auto results = bodyBuilder([&](mlir::OpBuilder& b) { return element = iterator->getElement(b, forOp.getInductionVar()); }, bodyArguments, builder);
      if (iterArgs.size()) {
         builder.create<scf::YieldOp>(loc, remap(results, builder));
         builder.eraseOp(terminator);
      }
      builder.restoreInsertionPoint(insertionPoint);
      return std::vector<Value>(forOp.getResults().begin(), forOp.getResults().end());
   }
};
std::unique_ptr<mlir::dsa::CollectionIterationImpl> mlir::dsa::CollectionIterationImpl::getImpl(Type collectionType, Value loweredCollection) {
   if (auto generic = collectionType.dyn_cast_or_null<mlir::dsa::GenericIterableType>()) {
      if (generic.getIteratorName() == "table_chunk_iterator") {
         if (auto recordBatchType = generic.getElementType().dyn_cast_or_null<mlir::dsa::RecordBatchType>()) {
            return std::make_unique<WhileIteratorIterationImpl>(std::make_unique<TableIterator2>(loweredCollection, recordBatchType));
         }
      }
   } else if (auto vector = collectionType.dyn_cast_or_null<mlir::util::BufferType>()) {
      return std::make_unique<ForIteratorIterationImpl>(std::make_unique<BufferIterator>(loweredCollection));
   } else if (auto recordBatch = collectionType.dyn_cast_or_null<mlir::dsa::RecordBatchType>()) {
      return std::make_unique<ForIteratorIterationImpl>(std::make_unique<RecordBatchIterator>(loweredCollection, recordBatch));
   }
   return std::unique_ptr<mlir::dsa::CollectionIterationImpl>();
}
