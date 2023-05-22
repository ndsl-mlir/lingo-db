# sql-to-mlir.cpp笔记

MLIRContext用于存储 MLIR 系统的全局状态。
MLIRContext 还管理了一组已注册的方言，这些方言定义了不同的操作和类型。
在解析过程中，MLIRContext 提供了必要的信息和资源，使得解析器能够根据指定的方言生成正确的中间表示。

DialectRegistry（方言注册表）：DialectRegistry 是一个容器，用于存储和管理 MLIR 中不同方言的实例。
在解析过程中，DialectRegistry 用于注册所需的方言，这些方言随后被加载到 MLIRContext 中。
注册表确保在生成中间表示时，解析器可以识别和处理这些方言中定义的操作和类型。