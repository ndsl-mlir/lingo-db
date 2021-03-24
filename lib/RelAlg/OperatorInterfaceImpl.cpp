#include "mlir/Dialect/RelAlg/IR/RelAlgOps.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Dialect/RelAlg/IR/RelAlgDialect.h"
#include <functional>
using namespace mlir::relalg;
using attribute_set=llvm::SmallPtrSet<mlir::relalg::RelationalAttribute*,8>;
using operator_list=llvm::SmallVector<Operator,4>;
attribute_set  mlir::relalg::detail::getCreatedAttributes(mlir::Operation* op) {
   attribute_set  creations;
   op->walk([&](AddAttrOp attrOp) {
      creations.insert(&attrOp.attr().getRelationalAttribute());
   });
   return creations;
}
static operator_list getChildOperators(mlir::Operation* parent){
   operator_list children;
   for(auto operand:parent->getOperands()){
      if(auto childOperator=mlir::dyn_cast_or_null<Operator>(operand.getDefiningOp())){
         children.push_back(childOperator);
      }
   }
   return children;

}
static void except(attribute_set& set,attribute_set& except){
   for(auto x:except){
      set.erase(x);
   }
}
static attribute_set collectAttributes(operator_list  operators,std::function<attribute_set(Operator)> fn){
   attribute_set collected;
   for(auto op:operators){
      auto res=fn(op);
      collected.insert(res.begin(),res.end());
   }
   return collected;
}
attribute_set mlir::relalg::detail::getUsedAttributes(mlir::Operation* op){
   attribute_set  creations;
   op->walk([&](GetAttrOp attrOp) {
     creations.insert(&attrOp.attr().getRelationalAttribute());
   });
   return creations;
}
attribute_set mlir::relalg::detail::getAvailableAttributes(mlir::Operation* op){
   Operator asOperator=mlir::dyn_cast_or_null<Operator>(op);
   auto collected=collectAttributes(getChildOperators(op),[](Operator op){return op.getAvailableAttributes();});
   auto self_created=asOperator.getCreatedAttributes();
   collected.insert(self_created.begin(),self_created.end());
   return collected;
}
attribute_set mlir::relalg::detail::getFreeAttributes(mlir::Operation* op){
   auto available=getAvailableAttributes(op);
   auto collected_free=collectAttributes(getChildOperators(op),[](Operator op){return op.getFreeAttributes();});
   auto used=getUsedAttributes(op);
   collected_free.insert(used.begin(),used.end());
   except(collected_free,available);
   return collected_free;
}

llvm::SmallPtrSet<::mlir::relalg::RelationalAttribute*,8> AggregationOp::getUsedAttributes() {
   auto used=mlir::relalg::detail::getUsedAttributes(getOperation());
   for(Attribute a:group_by_attrs()){
      used.insert(&a.dyn_cast_or_null<RelationalAttributeRefAttr>().getRelationalAttribute());
   }
   return used;
}
llvm::SmallPtrSet<::mlir::relalg::RelationalAttribute*,8> SortOp::getUsedAttributes() {
   attribute_set used;
   for(Attribute a:sortspecs()){
      used.insert(&a.dyn_cast_or_null<SortSpecificationAttr>().getAttr().getRelationalAttribute());
   }
   return used;
}

llvm::SmallPtrSet<::mlir::relalg::RelationalAttribute*,8> ConstRelationOp::getCreatedAttributes(){
   attribute_set creations;
   for(Attribute a:attributes()){
      creations.insert(&a.dyn_cast_or_null<RelationalAttributeDefAttr>().getRelationalAttribute());
   }
   return creations;
}
llvm::SmallPtrSet<::mlir::relalg::RelationalAttribute*,8> BaseTableOp::getCreatedAttributes(){
   attribute_set creations;
   for (auto mapping : columns()) {
      auto [_, attr] = mapping;
      auto relation_def_attr = attr.dyn_cast_or_null<RelationalAttributeDefAttr>();
      creations.insert(&relation_def_attr.getRelationalAttribute());
   }
   return creations;
}
llvm::SmallPtrSet<mlir::relalg::RelationalAttribute *, 8> mlir::relalg::AggregationOp::getAvailableAttributes() {
   attribute_set available=getCreatedAttributes();
   for(Attribute a:group_by_attrs()){
      available.insert(&a.dyn_cast_or_null<RelationalAttributeRefAttr>().getRelationalAttribute());
   }
   return available;
}
llvm::SmallPtrSet<mlir::relalg::RelationalAttribute *, 8> mlir::relalg::DistinctOp::getAvailableAttributes() {
   attribute_set available;
   for(Attribute a:attrs()){
      available.insert(&a.dyn_cast_or_null<RelationalAttributeRefAttr>().getRelationalAttribute());
   }
   return available;
}
#include "mlir/Dialect/RelAlg/IR/RelAlgOpsInterfaces.cpp.inc"
