#include "mlir/Conversion/DBToArrowStd/CollectionIteration.h"
#include "mlir/Conversion/DBToArrowStd/DBToArrowStd.h"
#include "mlir/Dialect/DB/IR/DBOps.h"
#include "mlir/Dialect/SCF/SCF.h"
#include "mlir/Dialect/util/UtilOps.h"
#include "mlir/Transforms/DialectConversion.h"
#include <llvm/Support/Debug.h>

using namespace mlir;
namespace {

class SortOpLowering : public ConversionPattern {
   db::codegen::FunctionRegistry& functionRegistry;

   public:
   explicit SortOpLowering(db::codegen::FunctionRegistry& functionRegistry, TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::SortOp::getOperationName(), 1, context), functionRegistry(functionRegistry) {}

   LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override {
      static size_t id = 0;
      using FunctionId = db::codegen::FunctionRegistry::FunctionId;
      mlir::db::SortOpAdaptor sortOpAdaptor(operands);
      auto sortOp = cast<mlir::db::SortOp>(op);
      auto ptrType = mlir::util::RefType::get(getContext(), IntegerType::get(getContext(), 8), llvm::Optional<int64_t>());

      ModuleOp parentModule = op->getParentOfType<ModuleOp>();
      Type elementType = sortOp.toSort().getType().cast<mlir::db::VectorType>().getElementType();
      FuncOp funcOp;
      {
         OpBuilder::InsertionGuard insertionGuard(rewriter);
         rewriter.setInsertionPointToStart(parentModule.getBody());
         funcOp = rewriter.create<FuncOp>(parentModule.getLoc(), "db_sort_compare" + std::to_string(id++), rewriter.getFunctionType(TypeRange({ptrType, ptrType}), TypeRange(mlir::db::BoolType::get(rewriter.getContext()))));
         auto* funcBody = new Block;
         funcBody->addArguments(TypeRange({ptrType, ptrType}));
         funcOp.body().push_back(funcBody);
         rewriter.setInsertionPointToStart(funcBody);
         Value left = funcBody->getArgument(0);
         Value right = funcBody->getArgument(1);

         Value genericMemrefLeft = rewriter.create<util::GenericMemrefCastOp>(sortOp.getLoc(), util::RefType::get(rewriter.getContext(), elementType, llvm::Optional<int64_t>()), left);
         Value genericMemrefRight = rewriter.create<util::GenericMemrefCastOp>(sortOp.getLoc(), util::RefType::get(rewriter.getContext(), elementType, llvm::Optional<int64_t>()), right);
         Value tupleLeft = rewriter.create<util::LoadOp>(sortOp.getLoc(), elementType, genericMemrefLeft, Value());
         Value tupleRight = rewriter.create<util::LoadOp>(sortOp.getLoc(), elementType, genericMemrefRight, Value());
         auto terminator = rewriter.create<mlir::ReturnOp>(sortOp.getLoc());
         Block* sortLambda = &sortOp.region().front();
         auto* sortLambdaTerminator = sortLambda->getTerminator();
         rewriter.mergeBlockBefore(sortLambda, terminator, {tupleLeft, tupleRight});
         mlir::db::YieldOp yieldOp = mlir::cast<mlir::db::YieldOp>(terminator->getPrevNode());
         Value x = yieldOp.results()[0];
         x.setType(rewriter.getI1Type()); //todo: bad hack ;)
         rewriter.create<mlir::ReturnOp>(sortOp.getLoc(), x);
         rewriter.eraseOp(sortLambdaTerminator);
         rewriter.eraseOp(terminator);
      }
      Type typedPtrType = util::RefType::get(rewriter.getContext(), typeConverter->convertType(elementType), -1);
      auto loaded = rewriter.create<mlir::util::LoadOp>(op->getLoc(), mlir::TupleType::get(rewriter.getContext(), TypeRange({rewriter.getIndexType(), rewriter.getIndexType(), typedPtrType})), sortOpAdaptor.toSort(), Value());
      auto unpacked = rewriter.create<util::UnPackOp>(sortOp.getLoc(), loaded);

      auto len = unpacked.getResult(0);
      auto values = unpacked.getResult(2);
      auto rawPtr = rewriter.create<util::GenericMemrefCastOp>(sortOp.getLoc(), ptrType, values);

      Value functionPointer = rewriter.create<mlir::ConstantOp>(sortOp->getLoc(), funcOp.type(), SymbolRefAttr::get(rewriter.getStringAttr(funcOp.sym_name())));
      Value elementSize = rewriter.create<util::SizeOfOp>(sortOp.getLoc(), rewriter.getIndexType(), elementType);
      functionRegistry.call(rewriter, sortOp->getLoc(), FunctionId::SortVector, {len, rawPtr, elementSize, functionPointer});
      rewriter.eraseOp(op);
      return success();
   }
};
class ForOpLowering : public ConversionPattern {
   db::codegen::FunctionRegistry& functionRegistry;

   public:
   explicit ForOpLowering(db::codegen::FunctionRegistry& functionRegistry, TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::ForOp::getOperationName(), 1, context), functionRegistry(functionRegistry) {}

   LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override {
      mlir::db::ForOpAdaptor forOpAdaptor(operands, op->getAttrDictionary());
      auto forOp = cast<mlir::db::ForOp>(op);
      auto argumentTypes = forOp.region().getArgumentTypes();
      auto collectionType = forOp.collection().getType().dyn_cast_or_null<mlir::db::CollectionType>();

      auto iterator = mlir::db::CollectionIterationImpl::getImpl(collectionType, forOp.collection(), functionRegistry);

      ModuleOp parentModule = op->getParentOfType<ModuleOp>();
      std::vector<Value> results = iterator->implementLoop(op->getLoc(), forOpAdaptor.initArgs(), forOp.until(), *typeConverter, rewriter, parentModule, [&](ValueRange values, OpBuilder builder) {
         auto yieldOp = cast<mlir::db::YieldOp>(forOp.getBody()->getTerminator());
         rewriter.mergeBlockBefore(forOp.getBody(), &*builder.getInsertionPoint(), values);
         std::vector<Value> results(yieldOp.results().begin(), yieldOp.results().end());
         rewriter.eraseOp(yieldOp);
         return results;
      });
      {
         OpBuilder::InsertionGuard insertionGuard(rewriter);
         forOp.region().push_back(new Block());
         forOp.region().front().addArguments(argumentTypes);
         rewriter.setInsertionPointToStart(&forOp.region().front());
         rewriter.create<mlir::db::YieldOp>(forOp.getLoc());
      }

      rewriter.replaceOp(op, results);
      return success();
   }
};

class LookupOpLowering : public ConversionPattern {
   public:
   explicit LookupOpLowering(TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::Lookup::getOperationName(), 1, context) {}

   LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override {
      auto loc = op->getLoc();
      mlir::db::LookupAdaptor lookupAdaptor(operands);
      auto unpacked = rewriter.create<mlir::util::UnPackOp>(loc, lookupAdaptor.collection());
      Value vec = unpacked.getResult(0);
      Value ht = unpacked.getResult(2);
      Value htMask = unpacked.getResult(3);
      Value hashed = rewriter.create<mlir::db::Hash>(loc, rewriter.getIndexType(), lookupAdaptor.key()); //hash key value
      Value buckedPos = rewriter.create<arith::AndIOp>(loc, htMask, hashed);
      Value pos = rewriter.create<util::LoadOp>(loc, rewriter.getIndexType(), ht, buckedPos);
      Value combined = rewriter.create<mlir::util::PackOp>(loc, ValueRange({pos, vec}));
      rewriter.replaceOp(op, combined);
      return success();
   }
};
} // namespace

void mlir::db::populateCollectionsToStdPatterns(mlir::db::codegen::FunctionRegistry& functionRegistry, mlir::TypeConverter& typeConverter, mlir::RewritePatternSet& patterns) {
   auto* context = patterns.getContext();

   patterns.insert<SortOpLowering>(functionRegistry, typeConverter, context);

   patterns.insert<ForOpLowering>(functionRegistry, typeConverter, context);
   patterns.insert<LookupOpLowering>(typeConverter, context);

   typeConverter.addSourceMaterialization([&](OpBuilder&, db::AggregationHashtableType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   typeConverter.addTargetMaterialization([&](OpBuilder&, db::AggregationHashtableType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   typeConverter.addSourceMaterialization([&](OpBuilder&, db::JoinHashtableType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   typeConverter.addTargetMaterialization([&](OpBuilder&, db::JoinHashtableType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   typeConverter.addSourceMaterialization([&](OpBuilder&, db::VectorType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   typeConverter.addTargetMaterialization([&](OpBuilder&, db::VectorType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   typeConverter.addSourceMaterialization([&](OpBuilder&, db::GenericIterableType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   typeConverter.addTargetMaterialization([&](OpBuilder&, db::GenericIterableType type, ValueRange valueRange, Location loc) {
      return valueRange.front();
   });
   auto indexType = IndexType::get(context);
   auto i8ptrType = mlir::util::RefType::get(context, IntegerType::get(context, 8), llvm::Optional<int64_t>());

   typeConverter.addConversion([&typeConverter, context, indexType](mlir::db::AggregationHashtableType aggregationHashtableType) {
      if (aggregationHashtableType.getKeyType().getTypes().empty()) {
         return (Type) typeConverter.convertType(aggregationHashtableType.getValType());
      } else {
         Type kvType = typeConverter.convertType(TupleType::get(context, {aggregationHashtableType.getKeyType(), aggregationHashtableType.getValType()}));

         Type entryType = TupleType::get(context, {indexType, indexType, kvType});

         auto vecType = mlir::util::RefType::get(context, entryType, -1);
         auto t = (Type) TupleType::get(context, {indexType, vecType});
         return t;
      }
   });
   typeConverter.addConversion([&typeConverter, indexType, context](mlir::db::JoinHashtableType aggregationHashtableType) {
      Type kvType = typeConverter.convertType(TupleType::get(context, {aggregationHashtableType.getKeyType(), aggregationHashtableType.getValType()}));
      Type entryType = TupleType::get(context, {indexType, kvType});

      auto vecType = mlir::util::RefType::get(context, entryType, -1);
      auto htType = util::RefType::get(context, indexType, -1);
      return (Type) TupleType::get(context, {vecType, indexType, htType, indexType});
   });

   typeConverter.addConversion([context, &typeConverter, indexType](mlir::db::VectorType vectorType) {
      Type entryType = typeConverter.convertType(vectorType.getElementType());
      auto arrayType = mlir::util::RefType::get(context, entryType, -1);
      return (Type) mlir::util::RefType::get(context, TupleType::get(context, {indexType, indexType, arrayType}), llvm::Optional<int64_t>());
   });
   typeConverter.addConversion([&typeConverter, context, i8ptrType, indexType](mlir::db::GenericIterableType genericIterableType) {
      Type elementType = genericIterableType.getElementType();
      Type nestedElementType = elementType;
      if (auto nested = elementType.dyn_cast_or_null<mlir::db::GenericIterableType>()) {
         nestedElementType = nested.getElementType();
      }
      if (genericIterableType.getIteratorName() == "table_chunk_iterator") {
         std::vector<Type> types;
         types.push_back(i8ptrType);
         if (auto tupleT = nestedElementType.dyn_cast_or_null<TupleType>()) {
            for (size_t i = 0; i < tupleT.getTypes().size(); i++) {
               types.push_back(indexType);
            }
         }
         return (Type) TupleType::get(context, types);
      } else if (genericIterableType.getIteratorName() == "table_row_iterator") {
         std::vector<Type> types;
         types.push_back(i8ptrType);
         if (auto tupleT = nestedElementType.dyn_cast_or_null<TupleType>()) {
            for (size_t i = 0; i < tupleT.getTypes().size(); i++) {
               types.push_back(indexType);
            }
         }
         return (Type) TupleType::get(context, types);
      } else if (genericIterableType.getIteratorName() == "join_ht_iterator") {
         auto ptrType = mlir::util::RefType::get(context, typeConverter.convertType(TupleType::get(context, {indexType, genericIterableType.getElementType()})), -1);
         return (Type) TupleType::get(context, {indexType, ptrType});
      } else if (genericIterableType.getIteratorName() == "join_ht_mod_iterator") {
         auto types = genericIterableType.getElementType().cast<mlir::TupleType>().getTypes();
         auto ptrType = mlir::util::RefType::get(context, typeConverter.convertType(TupleType::get(context, {indexType, types[0]})), -1);
         return (Type) TupleType::get(context, {indexType, ptrType});
      }
      return Type();
   });
}