module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "customer"} columns: {c_acctbal => @customer::@c_acctbal({type = !db.decimal<15, 2>}), c_address => @customer::@c_address({type = !db.string}), c_comment => @customer::@c_comment({type = !db.string}), c_custkey => @customer::@c_custkey({type = i32}), c_mktsegment => @customer::@c_mktsegment({type = !db.string}), c_name => @customer::@c_name({type = !db.string}), c_nationkey => @customer::@c_nationkey({type = i32}), c_phone => @customer::@c_phone({type = !db.string})}
    %1 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.selection %4 (%arg0: !relalg.tuple){
      %10 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem1::@l_comment({type = !db.string}), l_commitdate => @lineitem1::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem1::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem1::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem1::@l_linenumber({type = i32}), l_linestatus => @lineitem1::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem1::@l_orderkey({type = i32}), l_partkey => @lineitem1::@l_partkey({type = i32}), l_quantity => @lineitem1::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem1::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem1::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem1::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem1::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem1::@l_shipmode({type = !db.string}), l_suppkey => @lineitem1::@l_suppkey({type = i32}), l_tax => @lineitem1::@l_tax({type = !db.decimal<15, 2>})}
      %11 = relalg.aggregation %10 [@lineitem1::@l_orderkey] computes : [@aggr0::@tmp_attr0({type = !db.decimal<15, 2>})] (%arg1: !relalg.tuplestream,%arg2: !relalg.tuple){
        %22 = relalg.aggrfn sum @lineitem1::@l_quantity %arg1 : !db.decimal<15, 2>
        relalg.return %22 : !db.decimal<15, 2>
      }
      %12 = relalg.selection %11 (%arg1: !relalg.tuple){
        %22 = relalg.getcol %arg1 @aggr0::@tmp_attr0 : !db.decimal<15, 2>
        %23 = db.constant(300 : i32) : !db.decimal<15, 2>
        %24 = db.compare gt %22 : !db.decimal<15, 2>, %23 : !db.decimal<15, 2>
        relalg.return %24 : i1
      }
      %13 = relalg.selection %12 (%arg1: !relalg.tuple){
        %22 = relalg.getcol %arg1 @orders::@o_orderkey : i32
        %23 = relalg.getcol %arg1 @lineitem1::@l_orderkey : i32
        %24 = db.compare eq %22 : i32, %23 : i32
        relalg.return %24 : i1
      }
      %14 = relalg.exists %13
      %15 = relalg.getcol %arg0 @customer::@c_custkey : i32
      %16 = relalg.getcol %arg0 @orders::@o_custkey : i32
      %17 = db.compare eq %15 : i32, %16 : i32
      %18 = relalg.getcol %arg0 @orders::@o_orderkey : i32
      %19 = relalg.getcol %arg0 @lineitem::@l_orderkey : i32
      %20 = db.compare eq %18 : i32, %19 : i32
      %21 = db.and %14, %17, %20 : i1, i1, i1
      relalg.return %21 : i1
    }
    %6 = relalg.aggregation %5 [@customer::@c_name,@customer::@c_custkey,@orders::@o_orderkey,@orders::@o_orderdate,@orders::@o_totalprice] computes : [@aggr1::@tmp_attr1({type = !db.decimal<15, 2>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %10 = relalg.aggrfn sum @lineitem::@l_quantity %arg0 : !db.decimal<15, 2>
      relalg.return %10 : !db.decimal<15, 2>
    }
    %7 = relalg.sort %6 [(@orders::@o_totalprice,desc),(@orders::@o_orderdate,asc)]
    %8 = relalg.limit 100 %7
    %9 = relalg.materialize %8 [@customer::@c_name,@customer::@c_custkey,@orders::@o_orderkey,@orders::@o_orderdate,@orders::@o_totalprice,@aggr1::@tmp_attr1] => ["c_name", "c_custkey", "o_orderkey", "o_orderdate", "o_totalprice", "sum"] : !dsa.table
    return %9 : !dsa.table
  }
}
