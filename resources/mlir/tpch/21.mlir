module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
    %1 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @l1_::@l_comment({type = !db.string}), l_commitdate => @l1_::@l_commitdate({type = !db.date<day>}), l_discount => @l1_::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @l1_::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @l1_::@l_linenumber({type = i32}), l_linestatus => @l1_::@l_linestatus({type = !db.char<1>}), l_orderkey => @l1_::@l_orderkey({type = i32}), l_partkey => @l1_::@l_partkey({type = i32}), l_quantity => @l1_::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @l1_::@l_receiptdate({type = !db.date<day>}), l_returnflag => @l1_::@l_returnflag({type = !db.char<1>}), l_shipdate => @l1_::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @l1_::@l_shipinstruct({type = !db.string}), l_shipmode => @l1_::@l_shipmode({type = !db.string}), l_suppkey => @l1_::@l_suppkey({type = i32}), l_tax => @l1_::@l_tax({type = !db.decimal<15, 2>})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation::@n_name({type = !db.string}), n_nationkey => @nation::@n_nationkey({type = i32}), n_regionkey => @nation::@n_regionkey({type = i32})}
    %6 = relalg.crossproduct %4, %5
    %7 = relalg.selection %6 (%arg0: !relalg.tuple){
      %12 = relalg.getcol %arg0 @supplier::@s_suppkey : i32
      %13 = relalg.getcol %arg0 @l1_::@l_suppkey : i32
      %14 = db.compare eq %12 : i32, %13 : i32
      %15 = relalg.getcol %arg0 @orders::@o_orderkey : i32
      %16 = relalg.getcol %arg0 @l1_::@l_orderkey : i32
      %17 = db.compare eq %15 : i32, %16 : i32
      %18 = relalg.getcol %arg0 @orders::@o_orderstatus : !db.char<1>
      %19 = db.constant("F") : !db.char<1>
      %20 = db.compare eq %18 : !db.char<1>, %19 : !db.char<1>
      %21 = relalg.getcol %arg0 @l1_::@l_receiptdate : !db.date<day>
      %22 = relalg.getcol %arg0 @l1_::@l_commitdate : !db.date<day>
      %23 = db.compare gt %21 : !db.date<day>, %22 : !db.date<day>
      %24 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @l2_::@l_comment({type = !db.string}), l_commitdate => @l2_::@l_commitdate({type = !db.date<day>}), l_discount => @l2_::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @l2_::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @l2_::@l_linenumber({type = i32}), l_linestatus => @l2_::@l_linestatus({type = !db.char<1>}), l_orderkey => @l2_::@l_orderkey({type = i32}), l_partkey => @l2_::@l_partkey({type = i32}), l_quantity => @l2_::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @l2_::@l_receiptdate({type = !db.date<day>}), l_returnflag => @l2_::@l_returnflag({type = !db.char<1>}), l_shipdate => @l2_::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @l2_::@l_shipinstruct({type = !db.string}), l_shipmode => @l2_::@l_shipmode({type = !db.string}), l_suppkey => @l2_::@l_suppkey({type = i32}), l_tax => @l2_::@l_tax({type = !db.decimal<15, 2>})}
      %25 = relalg.selection %24 (%arg1: !relalg.tuple){
        %38 = relalg.getcol %arg1 @l2_::@l_orderkey : i32
        %39 = relalg.getcol %arg1 @l1_::@l_orderkey : i32
        %40 = db.compare eq %38 : i32, %39 : i32
        %41 = relalg.getcol %arg1 @l2_::@l_suppkey : i32
        %42 = relalg.getcol %arg1 @l1_::@l_suppkey : i32
        %43 = db.compare neq %41 : i32, %42 : i32
        %44 = db.and %40, %43 : i1, i1
        relalg.return %44 : i1
      }
      %26 = relalg.exists %25
      %27 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @l3_::@l_comment({type = !db.string}), l_commitdate => @l3_::@l_commitdate({type = !db.date<day>}), l_discount => @l3_::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @l3_::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @l3_::@l_linenumber({type = i32}), l_linestatus => @l3_::@l_linestatus({type = !db.char<1>}), l_orderkey => @l3_::@l_orderkey({type = i32}), l_partkey => @l3_::@l_partkey({type = i32}), l_quantity => @l3_::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @l3_::@l_receiptdate({type = !db.date<day>}), l_returnflag => @l3_::@l_returnflag({type = !db.char<1>}), l_shipdate => @l3_::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @l3_::@l_shipinstruct({type = !db.string}), l_shipmode => @l3_::@l_shipmode({type = !db.string}), l_suppkey => @l3_::@l_suppkey({type = i32}), l_tax => @l3_::@l_tax({type = !db.decimal<15, 2>})}
      %28 = relalg.selection %27 (%arg1: !relalg.tuple){
        %38 = relalg.getcol %arg1 @l3_::@l_orderkey : i32
        %39 = relalg.getcol %arg1 @l1_::@l_orderkey : i32
        %40 = db.compare eq %38 : i32, %39 : i32
        %41 = relalg.getcol %arg1 @l3_::@l_suppkey : i32
        %42 = relalg.getcol %arg1 @l1_::@l_suppkey : i32
        %43 = db.compare neq %41 : i32, %42 : i32
        %44 = relalg.getcol %arg1 @l3_::@l_receiptdate : !db.date<day>
        %45 = relalg.getcol %arg1 @l3_::@l_commitdate : !db.date<day>
        %46 = db.compare gt %44 : !db.date<day>, %45 : !db.date<day>
        %47 = db.and %40, %43, %46 : i1, i1, i1
        relalg.return %47 : i1
      }
      %29 = relalg.exists %28
      %30 = db.not %29 : i1
      %31 = relalg.getcol %arg0 @supplier::@s_nationkey : i32
      %32 = relalg.getcol %arg0 @nation::@n_nationkey : i32
      %33 = db.compare eq %31 : i32, %32 : i32
      %34 = relalg.getcol %arg0 @nation::@n_name : !db.string
      %35 = db.constant("SAUDI ARABIA") : !db.string
      %36 = db.compare eq %34 : !db.string, %35 : !db.string
      %37 = db.and %14, %17, %20, %23, %26, %30, %33, %36 : i1, i1, i1, i1, i1, i1, i1, i1
      relalg.return %37 : i1
    }
    %8 = relalg.aggregation %7 [@supplier::@s_name] computes : [@aggr0::@tmp_attr0({type = i64})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %12 = relalg.count %arg0
      relalg.return %12 : i64
    }
    %9 = relalg.sort %8 [(@aggr0::@tmp_attr0,desc),(@supplier::@s_name,asc)]
    %10 = relalg.limit 100 %9
    %11 = relalg.materialize %10 [@supplier::@s_name,@aggr0::@tmp_attr0] => ["s_name", "numwait"] : !dsa.table
    return %11 : !dsa.table
  }
}
