#include "mlir-support/parsing.h"
#include "mlir/Conversion/DBToArrowStd/DBToArrowStd.h"
#include <mlir/Conversion/DBToArrowStd/NullHandler.h>
#include <mlir/Dialect/util/UtilOps.h>

#include "mlir/Dialect/DB/IR/DBOps.h"
#include "mlir/Dialect/StandardOps/IR/Ops.h"

#include "mlir/Conversion/DBToArrowStd/FunctionRegistry.h"
#include "mlir/Transforms/DialectConversion.h" //
#include <llvm/ADT/TypeSwitch.h>

using namespace mlir;
namespace {

template <class OpClass, class LeftT, class RightT, class ResT>
class SimpleBinOpToFuncLowering : public ConversionPattern {
   std::function<Value(mlir::Location, LeftT, Value, ConversionPatternRewriter&)> processLeft;
   std::function<Value(mlir::Location, RightT, Value, ConversionPatternRewriter&)> processRight;
   std::function<std::vector<Value>(Value, Value)> combine;
   std::function<FuncOp(OpClass, LeftT, RightT, ConversionPatternRewriter& rewriter)> provideFunc;
   std::function<Value(mlir::Location, ResT, Value, ConversionPatternRewriter&)> processResult;

   public:
   explicit SimpleBinOpToFuncLowering(MLIRContext* context,
                                      std::function<Value(mlir::Location, LeftT, Value, ConversionPatternRewriter&)>
                                         processLeft,
                                      std::function<Value(mlir::Location, RightT, Value, ConversionPatternRewriter&)>
                                         processRight,
                                      std::function<std::vector<Value>(Value, Value)>
                                         combine,
                                      std::function<FuncOp(OpClass, LeftT, RightT, ConversionPatternRewriter& rewriter)>
                                         provideFunc,
                                      std::function<Value(mlir::Location, ResT, Value, ConversionPatternRewriter&)>
                                         processResult)
      : ConversionPattern(OpClass::getOperationName(), 1, context), processLeft(processLeft), processRight(processRight), combine(combine), provideFunc(provideFunc), processResult(processResult) {}
   LogicalResult
   matchAndRewrite(Operation* op, ArrayRef<Value> operands,
                   ConversionPatternRewriter& rewriter) const override {
      typename OpClass::Adaptor opAdaptor(operands);
      auto loc = op->getLoc();
      db::NullHandler nullHandler(*typeConverter, rewriter, loc);
      auto casted = cast<OpClass>(op);
      LeftT leftType = casted.left().getType().template dyn_cast_or_null<LeftT>();
      RightT rightType = casted.right().getType().template dyn_cast_or_null<RightT>();
      ResT resType = casted.getResult().getType().template dyn_cast_or_null<ResT>();
      if (!(leftType && rightType && resType)) {
         return failure();
      }

      Value left = nullHandler.getValue(casted.left(), opAdaptor.left());
      Value right = nullHandler.getValue(casted.right(), opAdaptor.right());

      left = processLeft(loc, leftType, left, rewriter);
      right = processRight(loc, rightType, right, rewriter);
      FuncOp func = provideFunc(casted, leftType, rightType, rewriter);
      auto call = rewriter.create<CallOp>(loc, func, combine(left, right));
      Value res = call.getResult(0);
      res = processResult(loc, resType, res, rewriter);
      rewriter.replaceOp(op, nullHandler.combineResult(res));
      return success();
   }
};
template <class OpClass, class ValT, class ResT>
class SimpleUnOpToFuncLowering : public ConversionPattern {
   std::function<Value(mlir::Location, ValT, Value, ConversionPatternRewriter&)> processVal;
   std::function<FuncOp(OpClass, ValT, ConversionPatternRewriter& rewriter)> provideFunc;
   std::function<Value(mlir::Location, ResT, Value, ConversionPatternRewriter&)> processResult;

   public:
   explicit SimpleUnOpToFuncLowering(MLIRContext* context,
                                     std::function<Value(mlir::Location, ValT, Value, ConversionPatternRewriter&)>
                                        processIn,
                                     std::function<FuncOp(OpClass, ValT, ConversionPatternRewriter& rewriter)>
                                        provideFunc,
                                     std::function<Value(mlir::Location, ResT, Value, ConversionPatternRewriter&)>
                                        processResult)
      : ConversionPattern(OpClass::getOperationName(), 1, context), processVal(processIn), provideFunc(provideFunc), processResult(processResult) {}
   LogicalResult
   matchAndRewrite(Operation* op, ArrayRef<Value> operands,
                   ConversionPatternRewriter& rewriter) const override {
      typename OpClass::Adaptor opAdaptor(operands);
      auto loc = op->getLoc();
      db::NullHandler nullHandler(*typeConverter, rewriter, loc);
      auto casted = cast<OpClass>(op);
      ValT valType = casted.val().getType().template dyn_cast_or_null<ValT>();
      ResT resType = casted.getResult().getType().template dyn_cast_or_null<ResT>();
      if (!(valType && resType)) {
         return failure();
      }
      Value val = nullHandler.getValue(casted.val(), opAdaptor.val());
      val = processVal(loc, valType, val, rewriter);
      FuncOp func = provideFunc(casted, valType, rewriter);
      auto call = rewriter.create<CallOp>(loc, func, val);
      Value res = call.getResult(0);
      res = processResult(loc, resType, res, rewriter);
      rewriter.replaceOp(op, nullHandler.combineResult(res));
      return success();
   }
};

class StringCastOpLowering : public ConversionPattern {
   db::codegen::FunctionRegistry& functionRegistry;

   public:
   explicit StringCastOpLowering(db::codegen::FunctionRegistry& functionRegistry, TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::CastOp::getOperationName(), 1, context), functionRegistry(functionRegistry) {}

   LogicalResult
   matchAndRewrite(Operation* op, ArrayRef<Value> operands,
                   ConversionPatternRewriter& rewriter) const override {
      using FunctionId = db::codegen::FunctionRegistry::FunctionId;

      auto castOp = cast<mlir::db::CastOp>(op);
      auto loc = op->getLoc();
      auto sourceType = castOp.val().getType();
      auto targetType = castOp.getType();
      auto sourceNullableType = sourceType.dyn_cast_or_null<mlir::db::NullableType>();
      auto targetNullableType = targetType.dyn_cast_or_null<mlir::db::NullableType>();
      auto scalarSourceType = sourceNullableType ? sourceNullableType.getType() : sourceType;
      auto scalarTargetType = targetNullableType ? targetNullableType.getType() : targetType;
      auto convertedTargetType = typeConverter->convertType(scalarTargetType);
      if (!scalarSourceType.isa<mlir::db::StringType>() && !scalarTargetType.isa<mlir::db::StringType>()) return failure();

      Value isNull;
      Value value;
      if (sourceNullableType) {
         auto unPackOp = rewriter.create<mlir::util::UnPackOp>(loc, operands[0]);
         isNull = unPackOp.vals()[0];
         value = unPackOp.vals()[1];
      } else {
         isNull = rewriter.create<arith::ConstantOp>(loc, rewriter.getIntegerAttr(rewriter.getI1Type(), 0));
         value = operands[0];
      }
      if (scalarSourceType == scalarTargetType) {
         //nothing to do here
      } else if (auto stringType = scalarSourceType.dyn_cast_or_null<db::StringType>()) {
         if (auto intWidth = getIntegerWidth(scalarTargetType, false)) {
            value = functionRegistry.call(rewriter, loc, FunctionId::CastStringToInt64, ValueRange({isNull, value}))[0];
            if (intWidth < 64) {
               value = rewriter.create<arith::TruncIOp>(loc, convertedTargetType, value);
            }
         } else if (auto floatType = scalarTargetType.dyn_cast_or_null<db::FloatType>()) {
            FunctionId castFn = floatType.getWidth() == 32 ? FunctionId ::CastStringToFloat32 : FunctionId ::CastStringToFloat64;
            value = functionRegistry.call(rewriter, loc, castFn, ValueRange({isNull, value}))[0];
         } else if (auto decimalType = scalarTargetType.dyn_cast_or_null<db::DecimalType>()) {
            auto scale = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(decimalType.getS()));
            value = functionRegistry.call(rewriter, loc, FunctionId ::CastStringToDecimal, ValueRange({isNull, value, scale}))[0];
            if (typeConverter->convertType(decimalType).cast<mlir::IntegerType>().getWidth() < 128) {
               auto converted = rewriter.create<arith::TruncIOp>(loc, typeConverter->convertType(decimalType), value);
               value = converted;
            }
         } else {
            return failure();
         }
      } else if (auto intWidth = getIntegerWidth(scalarSourceType, false)) {
         if (scalarTargetType.isa<db::StringType>()) {
            if (intWidth < 64) {
               value = rewriter.create<arith::ExtSIOp>(loc, rewriter.getI64Type(), value);
            }
            value = functionRegistry.call(rewriter, loc, FunctionId ::CastInt64ToString, ValueRange({isNull, value}))[0];
         } else {
            return failure();
         }
      } else if (auto floatType = scalarSourceType.dyn_cast_or_null<db::FloatType>()) {
         if (scalarTargetType.isa<db::StringType>()) {
            FunctionId castFn = floatType.getWidth() == 32 ? FunctionId ::CastFloat32ToString : FunctionId ::CastFloat64ToString;
            value = functionRegistry.call(rewriter, loc, castFn, ValueRange({isNull, value}))[0];

         } else {
            return failure();
         }
      } else if (auto decimalSourceType = scalarSourceType.dyn_cast_or_null<db::DecimalType>()) {
         if (scalarTargetType.isa<db::StringType>()) {
            auto scale = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32Type(), rewriter.getI32IntegerAttr(decimalSourceType.getS()));
            if (typeConverter->convertType(decimalSourceType).cast<mlir::IntegerType>().getWidth() < 128) {
               auto converted = rewriter.create<arith::ExtSIOp>(loc, rewriter.getIntegerType(128), value);
               value = converted;
            }
            value = functionRegistry.call(rewriter, loc, FunctionId ::CastDecimalToString, ValueRange({isNull, value, scale}))[0];

         } else {
            return failure();
         }
      } else if (auto charType = scalarSourceType.dyn_cast_or_null<db::CharType>()) {
         if (scalarTargetType.isa<db::StringType>()) {
            if (charType.getBytes() < 8) {
               value = rewriter.create<arith::ExtSIOp>(loc, rewriter.getI64Type(), value);
            }
            auto bytes = rewriter.create<arith::ConstantOp>(loc, rewriter.getI64Type(), rewriter.getI64IntegerAttr(charType.getBytes()));
            value = functionRegistry.call(rewriter, loc, FunctionId ::CastCharToString, ValueRange({isNull, value, bytes}))[0];
         } else {
            return failure();
         }
      } else {
         return failure();
      }
      //todo convert types
      if (targetNullableType) {
         Value combined = rewriter.create<mlir::util::PackOp>(loc, ValueRange({isNull, value}));
         rewriter.replaceOp(op, combined);
      } else {
         rewriter.replaceOp(op, value);
      }
      return success();
   }
};
class StringCmpOpLowering : public ConversionPattern {
   db::codegen::FunctionRegistry& functionRegistry;
   using FuncId = mlir::db::codegen::FunctionRegistry::FunctionId;

   public:
   explicit StringCmpOpLowering(db::codegen::FunctionRegistry& functionRegistry, TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::CmpOp::getOperationName(), 1, context), functionRegistry(functionRegistry) {}
   mlir::db::codegen::FunctionRegistry::FunctionId funcForStrCompare(db::DBCmpPredicate pred) const {
      switch (pred) {
         case db::DBCmpPredicate::eq:
            return FuncId::CmpStringEQ;
         case db::DBCmpPredicate::neq:
            return FuncId::CmpStringNEQ;
         case db::DBCmpPredicate::lt:
            return FuncId::CmpStringLT;
         case db::DBCmpPredicate::gt:
            return FuncId::CmpStringGT;
         case db::DBCmpPredicate::lte:
            return FuncId::CmpStringLTE;
         case db::DBCmpPredicate::gte:
            return FuncId::CmpStringGTE;
         case db::DBCmpPredicate::like:
            return FuncId::CmpStringLike;
      }
      assert(false && "unexpected case");
      return FuncId::CmpStringEQ;
   }
   bool stringIsOk(std::string str) const {
      for (auto x : str) {
         if (!std::isalnum(x)) return false;
      }
      return true;
   }
   LogicalResult
   matchAndRewrite(Operation* op, ArrayRef<Value> operands,
                   ConversionPatternRewriter& rewriter) const override {
      auto cmpOp = cast<db::CmpOp>(op);
      db::CmpOpAdaptor adaptor(operands);
      auto type = cmpOp.left().getType();
      if (auto nullableType = type.dyn_cast_or_null<mlir::db::NullableType>()) {
         type = nullableType.getType();
      }
      if (!type.isa<db::StringType>()) {
         return failure();
      }
      db::NullHandler nullHandler(*typeConverter, rewriter, cmpOp->getLoc());
      Value left = nullHandler.getValue(cmpOp.left(), adaptor.left());
      Value right = nullHandler.getValue(cmpOp.right(), adaptor.right());
      using FuncId = mlir::db::codegen::FunctionRegistry::FunctionId;
      if (cmpOp.predicate() == db::DBCmpPredicate::like) {
         if (auto* defOp = cmpOp.right().getDefiningOp()) {
            if (auto constOp = mlir::dyn_cast_or_null<mlir::db::ConstantOp>(defOp)) {
               std::string likeCond = constOp.getValue().cast<mlir::StringAttr>().str();
               if (likeCond.ends_with('%') && stringIsOk(likeCond.substr(0, likeCond.size() - 1))) {
                  auto newConst = rewriter.create<mlir::db::ConstantOp>(cmpOp->getLoc(), mlir::db::StringType::get(getContext()), rewriter.getStringAttr(likeCond.substr(0, likeCond.size() - 1)));
                  Value res = functionRegistry.call(rewriter, cmpOp->getLoc(), FuncId ::CmpStringStartsWith, ValueRange({nullHandler.isNull(), left, rewriter.getRemappedValue(newConst)}))[0];
                  rewriter.replaceOp(op, nullHandler.combineResult(res));
                  return success();
               } else if (likeCond.starts_with('%') && stringIsOk(likeCond.substr(1, likeCond.size() - 1))) {
                  auto newConst = rewriter.create<mlir::db::ConstantOp>(cmpOp->getLoc(), mlir::db::StringType::get(getContext()), rewriter.getStringAttr(likeCond.substr(1, likeCond.size() - 1)));
                  Value res = functionRegistry.call(rewriter, cmpOp->getLoc(), FuncId ::CmpStringEndsWith, ValueRange({nullHandler.isNull(), left, rewriter.getRemappedValue(newConst)}))[0];
                  rewriter.replaceOp(op, nullHandler.combineResult(res));
                  return success();
               }
            }
         }
      }
      FuncId cmpFunc = funcForStrCompare(cmpOp.predicate());
      Value res = functionRegistry.call(rewriter, cmpOp->getLoc(), cmpFunc, ValueRange({nullHandler.isNull(), left, right}))[0];
      rewriter.replaceOp(op, nullHandler.combineResult(res));
      return success();
   }
};
class DumpOpLowering : public ConversionPattern {
   db::codegen::FunctionRegistry& functionRegistry;

   public:
   explicit DumpOpLowering(db::codegen::FunctionRegistry& functionRegistry, TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::DumpOp::getOperationName(), 1, context), functionRegistry(functionRegistry) {}

   LogicalResult
   matchAndRewrite(Operation* op, ArrayRef<Value> operands,
                   ConversionPatternRewriter& rewriter) const override {
      using FunctionId = mlir::db::codegen::FunctionRegistry::FunctionId;
      mlir::db::DumpOp::Adaptor dumpOpAdaptor(operands);
      auto loc = op->getLoc();
      auto printOp = cast<mlir::db::DumpOp>(op);
      Value val = printOp.val();
      auto i128Type = IntegerType::get(rewriter.getContext(), 128);
      auto i64Type = IntegerType::get(rewriter.getContext(), 64);
      auto nullableType = val.getType().dyn_cast_or_null<mlir::db::NullableType>();
      auto baseType = nullableType ? nullableType.getType() : val.getType();

      auto f64Type = FloatType::getF64(rewriter.getContext());
      Value isNull;
      if (nullableType) {
         auto unPackOp = rewriter.create<mlir::util::UnPackOp>(loc, dumpOpAdaptor.val());
         isNull = unPackOp.vals()[0];
         val = unPackOp.vals()[1];
      } else {
         isNull = rewriter.create<arith::ConstantOp>(loc, rewriter.getIntegerAttr(rewriter.getI1Type(), 0));
         val = dumpOpAdaptor.val();
      }

      if (isIntegerType(baseType, 1)) {
         functionRegistry.call(rewriter, loc, FunctionId::DumpBool, ValueRange({isNull, val}));
      } else if (auto intWidth = getIntegerWidth(baseType, false)) {
         if (intWidth < 64) {
            val = rewriter.create<arith::ExtSIOp>(loc, i64Type, val);
         }
         functionRegistry.call(rewriter, loc, FunctionId::DumpInt, ValueRange({isNull, val}));
      } else if (auto uIntWidth = getIntegerWidth(baseType, true)) {
         if (uIntWidth < 64) {
            val = rewriter.create<arith::ExtUIOp>(loc, i64Type, val);
         }
         functionRegistry.call(rewriter, loc, FunctionId::DumpUInt, ValueRange({isNull, val}));
      } else if (auto decType = baseType.dyn_cast_or_null<mlir::db::DecimalType>()) {
         if (typeConverter->convertType(decType).cast<mlir::IntegerType>().getWidth() < 128) {
            auto converted = rewriter.create<arith::ExtSIOp>(loc, rewriter.getIntegerType(128), val);
            val = converted;
         }
         Value low = rewriter.create<arith::TruncIOp>(loc, i64Type, val);
         Value shift = rewriter.create<arith::ConstantOp>(loc, rewriter.getIntegerAttr(i128Type, 64));
         Value scale = rewriter.create<arith::ConstantOp>(loc, rewriter.getI32IntegerAttr(decType.getS()));
         Value high = rewriter.create<arith::ShRUIOp>(loc, i128Type, val, shift);
         high = rewriter.create<arith::TruncIOp>(loc, i64Type, high);
         functionRegistry.call(rewriter, loc, FunctionId::DumpDecimal, ValueRange({isNull, low, high, scale}));
      } else if (auto dateType = baseType.dyn_cast_or_null<mlir::db::DateType>()) {
         if (dateType.getUnit() == mlir::db::DateUnitAttr::millisecond) {
            functionRegistry.call(rewriter, loc, FunctionId::DumpDateMillisecond, ValueRange({isNull, val}));
         } else {
            functionRegistry.call(rewriter, loc, FunctionId::DumpDateDay, ValueRange({isNull, val}));
         }
      } else if (auto timestampType = baseType.dyn_cast_or_null<mlir::db::TimestampType>()) {
         FunctionId functionId;
         switch (timestampType.getUnit()) {
            case mlir::db::TimeUnitAttr::second: functionId = FunctionId::DumpTimestampSecond; break;
            case mlir::db::TimeUnitAttr::millisecond: functionId = FunctionId::DumpTimestampMillisecond; break;
            case mlir::db::TimeUnitAttr::microsecond: functionId = FunctionId::DumpTimestampMicrosecond; break;
            case mlir::db::TimeUnitAttr::nanosecond: functionId = FunctionId::DumpTimestampNanosecond; break;
         }
         functionRegistry.call(rewriter, loc, functionId, ValueRange({isNull, val}));
      } else if (auto intervalType = baseType.dyn_cast_or_null<mlir::db::IntervalType>()) {
         if (intervalType.getUnit() == mlir::db::IntervalUnitAttr::months) {
            functionRegistry.call(rewriter, loc, FunctionId::DumpIntervalMonths, ValueRange({isNull, val}));
         } else {
            functionRegistry.call(rewriter, loc, FunctionId::DumpIntervalDayTime, ValueRange({isNull, val}));
         }

      } else if (auto floatType = baseType.dyn_cast_or_null<mlir::db::FloatType>()) {
         if (floatType.getWidth() < 64) {
            val = rewriter.create<arith::ExtFOp>(loc, f64Type, val);
         }
         functionRegistry.call(rewriter, loc, FunctionId::DumpFloat, ValueRange({isNull, val}));
      } else if (baseType.isa<mlir::db::StringType>()) {
         functionRegistry.call(rewriter, loc, FunctionId::DumpString, ValueRange({isNull, val}));
      } else if (auto charType = baseType.dyn_cast_or_null<mlir::db::CharType>()) {
         Value numBytes = rewriter.create<arith::ConstantOp>(loc, rewriter.getI64IntegerAttr(charType.getBytes()));
         if (charType.getBytes() < 8) {
            val = rewriter.create<arith::ExtSIOp>(loc, i64Type, val);
         }
         functionRegistry.call(rewriter, loc, FunctionId::DumpChar, ValueRange({isNull, val, numBytes}));
      }
      rewriter.eraseOp(op);

      return success();
   }
};
class DumpIndexOpLowering : public ConversionPattern {
   db::codegen::FunctionRegistry& functionRegistry;

   public:
   explicit DumpIndexOpLowering(db::codegen::FunctionRegistry& functionRegistry, TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::DumpIndexOp::getOperationName(), 1, context), functionRegistry(functionRegistry) {}

   LogicalResult matchAndRewrite(Operation* op, ArrayRef<Value> operands, ConversionPatternRewriter& rewriter) const override {
      using FunctionId = db::codegen::FunctionRegistry::FunctionId;
      functionRegistry.call(rewriter, op->getLoc(), FunctionId::DumpIndex, operands[0]);

      rewriter.eraseOp(op);

      return success();
   }
};

class DecimalMulLowering : public ConversionPattern {
   public:
   explicit DecimalMulLowering(TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::MulOp::getOperationName(), 1, context) {}

   LogicalResult
   matchAndRewrite(Operation* op, ArrayRef<Value> operands,
                   ConversionPatternRewriter& rewriter) const override {
      auto addOp = cast<mlir::db::MulOp>(op);
      typename mlir::db::MulOpAdaptor adaptor(operands);
      db::NullHandler nullHandler(*typeConverter, rewriter, op->getLoc());
      Value left = nullHandler.getValue(addOp.left(), adaptor.left());
      Value right = nullHandler.getValue(addOp.right(), adaptor.right());
      if (left.getType() != right.getType()) {
         return failure();
      }
      auto type = addOp.getType();
      auto nullableType = type.dyn_cast_or_null<mlir::db::NullableType>();
      auto baseType = nullableType ? nullableType.getType() : type;
      if (auto decimalType = baseType.template dyn_cast_or_null<mlir::db::DecimalType>()) {
         auto [low, high] = support::getDecimalScaleMultiplier(decimalType.getS());
         std::vector<uint64_t> parts = {low, high};
         auto stdType = typeConverter->convertType(decimalType);
         auto divider = rewriter.create<arith::ConstantOp>(addOp->getLoc(), stdType, rewriter.getIntegerAttr(stdType, APInt(stdType.cast<mlir::IntegerType>().getWidth(), parts)));
         auto multiplied = rewriter.create<mlir::arith::MulIOp>(op->getLoc(), stdType, left, right);
         auto replacement = rewriter.create<arith::DivSIOp>(op->getLoc(), stdType, multiplied, divider);
         rewriter.replaceOp(op, nullHandler.combineResult(replacement));

         return success();
      }
      return failure();
   }
};
class FreeOpLowering : public ConversionPattern {
   public:
   explicit FreeOpLowering(db::codegen::FunctionRegistry& functionRegistry, TypeConverter& typeConverter, MLIRContext* context)
      : ConversionPattern(typeConverter, mlir::db::FreeOp::getOperationName(), 1, context) {}

   LogicalResult
   matchAndRewrite(Operation* op, ArrayRef<Value> operands,
                   ConversionPatternRewriter& rewriter) const override {
      /*      auto freeOp = cast<mlir::db::FreeOp>(op);
      mlir::db::FreeOpAdaptor adaptor(operands);
      auto val = adaptor.val();
      auto rewritten = ::llvm::TypeSwitch<::mlir::Type, bool>(freeOp.val().getType())
                          .Case<::mlir::db::AggregationHashtableType>([&](::mlir::db::AggregationHashtableType type) {
                             if (!type.getKeyType().getTypes().empty()) {
                                //todo free aggregation hashtable
                                //functionRegistry.call(rewriter, loc, FunctionId::AggrHtFree, val);
                             }
                             return true;
                          })
                          .Case<::mlir::db::VectorType>([&](::mlir::db::VectorType) {
                             //todo: free vector
                             //functionRegistry.call(rewriter, loc, FunctionId::VectorFree, val);
                             return true;
                          })
                          .Case<::mlir::db::JoinHashtableType>([&](::mlir::db::JoinHashtableType) {
                             //todo: free join hashtable
                             //functionRegistry.call(rewriter, loc, FunctionId::JoinHtFree, val);
                             return true;
                          })
                          .Default([&](::mlir::Type) { return false; });
      if (rewritten) {
         rewriter.eraseOp(op);
         return success();
      } else {
         return failure();
      }
      */
      rewriter.eraseOp(op);
      return success();
   }
};
} // namespace

void mlir::db::populateRuntimeSpecificScalarToStdPatterns(mlir::db::codegen::FunctionRegistry& functionRegistry, mlir::TypeConverter& typeConverter, mlir::RewritePatternSet& patterns) {
   using FunctionId = db::codegen::FunctionRegistry::FunctionId;

   auto ensureDate64 = [](mlir::Location loc, mlir::db::DateType dateType, Value v, ConversionPatternRewriter& rewriter) {
      if (dateType.getUnit() == db::DateUnitAttr::day) {
         auto i64Type = IntegerType::get(rewriter.getContext(), 64);
         v = rewriter.template create<arith::ExtUIOp>(loc, i64Type, v);
         Value multiplier = rewriter.create<arith::ConstantOp>(loc, rewriter.getIntegerAttr(i64Type, 24 * 60 * 60 * 1000));
         v = rewriter.template create<arith::MulIOp>(loc, v, multiplier);
         return v;
      } else {
         return v;
      }
   };
   auto negateInterval = [](mlir::Location loc, mlir::db::IntervalType dateType, Value v, ConversionPatternRewriter& rewriter) {
      Value multiplier = rewriter.template create<arith::ConstantOp>(loc, rewriter.getIntegerAttr(v.getType(), -1));
      return rewriter.template create<arith::MulIOp>(loc, v, multiplier);
   };
   auto transformDateBack = [](mlir::Location loc, mlir::db::DateType dateType, Value v, ConversionPatternRewriter& rewriter) {
      if (dateType.getUnit() == db::DateUnitAttr::day) {
         auto i64Type = IntegerType::get(rewriter.getContext(), 64);
         auto i32Type = IntegerType::get(rewriter.getContext(), 32);
         Value multiplier = rewriter.template create<arith::ConstantOp>(loc, rewriter.getIntegerAttr(i64Type, 24 * 60 * 60 * 1000));
         v = rewriter.template create<arith::DivUIOp>(loc, v, multiplier);
         v = rewriter.template create<arith::TruncIOp>(loc, i32Type, v);
         return v;
      }
      return v;
   };
   auto identity = [](auto, auto, Value v, auto&) { return v; };
   auto rightleft = [](Value left, Value right) { return std::vector<Value>({right, left}); };
   auto dateAddFunction = [&](Operation* op, mlir::db::DateType dateType, mlir::db::IntervalType intervalType, ConversionPatternRewriter& rewriter) {
      if (intervalType.getUnit() == mlir::db::IntervalUnitAttr::daytime) {
         return functionRegistry.getFunction(rewriter, FunctionId::TimestampAddMillis);
      } else {
         return functionRegistry.getFunction(rewriter, FunctionId::TimestampAddMonth);
      }
   };
   auto dateExtractFunction = [&](mlir::db::DateExtractOp dateExtractOp, mlir::db::DateType dateType, ConversionPatternRewriter& rewriter) {
      FunctionId functionId;
      switch (dateExtractOp.unit()) {
         case mlir::db::ExtractableTimeUnitAttr::second: functionId = FunctionId::DateExtractSecond; break;
         case mlir::db::ExtractableTimeUnitAttr::minute: functionId = FunctionId::DateExtractMinute; break;
         case mlir::db::ExtractableTimeUnitAttr::hour: functionId = FunctionId::DateExtractHour; break;
         case mlir::db::ExtractableTimeUnitAttr::dow: functionId = FunctionId::DateExtractDow; break;
         //case mlir::db::ExtractableTimeUnitAttr::week: functionId = FunctionId::DateExtractWeek; break;
         case mlir::db::ExtractableTimeUnitAttr::day: functionId = FunctionId::DateExtractDay; break;
         case mlir::db::ExtractableTimeUnitAttr::month: functionId = FunctionId::DateExtractMonth; break;
         case mlir::db::ExtractableTimeUnitAttr::doy: functionId = FunctionId::DateExtractDoy; break;
         //case mlir::db::ExtractableTimeUnitAttr::quarter: functionId = FunctionId::DateExtractQuarter; break;
         case mlir::db::ExtractableTimeUnitAttr::year: functionId = FunctionId::DateExtractYear; break;
         //case mlir::db::ExtractableTimeUnitAttr::decade: functionId = FunctionId::DateExtractDecade; break;
         //case mlir::db::ExtractableTimeUnitAttr::century: functionId = FunctionId::DateExtractCentury; break;
         //case mlir::db::ExtractableTimeUnitAttr::millennium: functionId = FunctionId::DateExtractMillenium; break;
         default:
            assert(false && "not implemented yet");
      }
      return functionRegistry.getFunction(rewriter, functionId);
   };

   patterns.insert<SimpleBinOpToFuncLowering<mlir::db::DateAddOp, mlir::db::DateType, mlir::db::IntervalType, mlir::db::DateType>>(
      patterns.getContext(), ensureDate64, identity, rightleft, dateAddFunction, transformDateBack);
   patterns.insert<SimpleBinOpToFuncLowering<mlir::db::DateSubOp, mlir::db::DateType, mlir::db::IntervalType, mlir::db::DateType>>(
      patterns.getContext(), ensureDate64, negateInterval, rightleft, dateAddFunction, transformDateBack);
   patterns.insert<SimpleUnOpToFuncLowering<mlir::db::DateExtractOp, mlir::db::DateType, mlir::IntegerType>>(
      patterns.getContext(), ensureDate64, dateExtractFunction, identity);
   patterns.insert<StringCmpOpLowering>(functionRegistry, typeConverter, patterns.getContext());
   patterns.insert<StringCastOpLowering>(functionRegistry, typeConverter, patterns.getContext());
   patterns.insert<DumpOpLowering>(functionRegistry, typeConverter, patterns.getContext());
   patterns.insert<DumpIndexOpLowering>(functionRegistry, typeConverter, patterns.getContext());
   patterns.insert<FreeOpLowering>(functionRegistry, typeConverter, patterns.getContext());
   patterns.insert<DecimalMulLowering>(typeConverter, patterns.getContext());
}