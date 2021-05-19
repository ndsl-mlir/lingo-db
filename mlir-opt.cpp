#include "mlir/IR/Dialect.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Support/FileUtilities.h"
#include "mlir/Support/MlirOptMain.h"

#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/RelAlg/IR/RelAlgDialect.h"
#include "mlir/Dialect/RelAlg/Passes.h"

#include "mlir/Dialect/DB/IR/DBDialect.h"
#include "mlir/Dialect/util/Passes.h"
#include "mlir/Dialect/util/UtilDialect.h"

#include "mlir/Conversion/DBToArrowStd/DBToArrowStdPass.h"
#include "mlir/Conversion/SCFToStandard/SCFToStandard.h"
#include "mlir/Conversion/StandardToLLVM/ConvertStandardToLLVMPass.h"
#include "mlir/Dialect/SCF/SCF.h"

#include "mlir/Dialect/LLVMIR/LLVMDialect.h"

namespace {
struct ToLLVMLoweringPass
   : public mlir::PassWrapper<ToLLVMLoweringPass, mlir::OperationPass<mlir::ModuleOp>> {
   void getDependentDialects(mlir::DialectRegistry& registry) const override {
      registry.insert<mlir::LLVM::LLVMDialect, mlir::scf::SCFDialect, mlir::memref::MemRefDialect>();
   }
   void runOnOperation() final;
};
} // end anonymous namespace

void ToLLVMLoweringPass::runOnOperation() {
   // The first thing to define is the conversion target. This will define the
   // final target for this lowering. For this lowering, we are only targeting
   // the LLVM dialect.
   mlir::LLVMConversionTarget target(getContext());
   target.addLegalOp<mlir::ModuleOp>();

   // During this lowering, we will also be lowering the MemRef types, that are
   // currently being operated on, to a representation in LLVM. To perform this
   // conversion we use a TypeConverter as part of the lowering. This converter
   // details how one type maps to another. This is necessary now that we will be
   // doing more complicated lowerings, involving loop region arguments.
   mlir::LowerToLLVMOptions options(&getContext());
   //options.emitCWrappers = true;
   mlir::LLVMTypeConverter typeConverter(&getContext(), options);

   // Now that the conversion target has been defined, we need to provide the
   // patterns used for lowering. At this point of the compilation process, we
   // have a combination of `toy`, `affine`, and `std` operations. Luckily, there
   // are already exists a set of patterns to transform `affine` and `std`
   // dialects. These patterns lowering in multiple stages, relying on transitive
   // lowerings. Transitive lowering, or A->B->C lowering, is when multiple
   // patterns must be applied to fully transform an illegal operation into a
   // set of legal ones.
   mlir::RewritePatternSet patterns(&getContext());
   populateAffineToStdConversionPatterns(patterns);
   populateLoopToStdConversionPatterns(patterns);
   mlir::util::populateUtilToLLVMConversionPatterns(typeConverter, patterns);
   populateStdToLLVMConversionPatterns(typeConverter, patterns);
   // We want to completely lower to LLVM, so we use a `FullConversion`. This
   // ensures that only legal operations will remain after the conversion.
   auto module = getOperation();
   if (auto mainFunc = module.lookupSymbol<mlir::FuncOp>("main")) {
      mainFunc->setAttr("llvm.emit_c_interface", mlir::UnitAttr::get(&getContext()));
   }
   if (failed(applyFullConversion(module, target, std::move(patterns))))
      signalPassFailure();
}

int main(int argc, char** argv) {
   mlir::registerAllPasses();
   ::mlir::registerPass("relalg-extract-nested-operators", "extract nested operators", []() -> std::unique_ptr<::mlir::Pass> {
      return mlir::relalg::createExtractNestedOperatorsPass();
   });
   ::mlir::registerPass("relalg-decompose-lambdas", "extract nested operators", []() -> std::unique_ptr<::mlir::Pass> {
      return mlir::relalg::createDecomposeLambdasPass();
   });
   ::mlir::registerPass("relalg-implicit-to-explicit-joins", "implicit to explicit joins", []() -> std::unique_ptr<::mlir::Pass> {
      return mlir::relalg::createImplicitToExplicitJoinsPass();
   });
   ::mlir::registerPass("relalg-unnesting", "unnest depending joins", []() -> std::unique_ptr<::mlir::Pass> {
      return mlir::relalg::createUnnestingPass();
   });
   ::mlir::registerPass("relalg-pushdown", "pushdown ", []() -> std::unique_ptr<::mlir::Pass> {
      return mlir::relalg::createPushdownPass();
   });
   ::mlir::registerPass("relalg-optimize-join-order", "joinorder", []() -> std::unique_ptr<::mlir::Pass> {
      return mlir::relalg::createOptimizeJoinOrderPass();
   });
   ::mlir::registerPass("to-arrow-std", "tostd", []() -> std::unique_ptr<::mlir::Pass> {
      return mlir::db::createLowerToStdPass();
   });
   ::mlir::registerPass("to-llvm", "tollvm", []() -> std::unique_ptr<::mlir::Pass> {
      return std::make_unique<ToLLVMLoweringPass>();
   });
   mlir::DialectRegistry registry;
   registry.insert<mlir::relalg::RelAlgDialect>();
   registry.insert<mlir::db::DBDialect>();
   registry.insert<mlir::StandardOpsDialect>();
   registry.insert<mlir::memref::MemRefDialect>();
   registry.insert<mlir::util::UtilDialect>();
   registry.insert<mlir::scf::SCFDialect>();

   return failed(
      mlir::MlirOptMain(argc, argv, "DB dialects optimization driver\n", registry));
}
