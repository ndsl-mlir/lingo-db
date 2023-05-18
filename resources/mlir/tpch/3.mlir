module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "customer"} columns: {c_acctbal => @customer::@c_acctbal({type = !db.decimal<15, 2>}), c_address => @customer::@c_address({type = !db.string}), c_comment => @customer::@c_comment({type = !db.string}), c_custkey => @customer::@c_custkey({type = i32}), c_mktsegment => @customer::@c_mktsegment({type = !db.string}), c_name => @customer::@c_name({type = !db.string}), c_nationkey => @customer::@c_nationkey({type = i32}), c_phone => @customer::@c_phone({type = !db.string})}
    %1 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.selection %4 (%arg0: !relalg.tuple){
      %11 = relalg.getcol %arg0 @customer::@c_mktsegment : !db.string
      %12 = db.constant("BUILDING") : !db.string
      %13 = db.compare eq %11 : !db.string, %12 : !db.string
      %14 = relalg.getcol %arg0 @customer::@c_custkey : i32
      %15 = relalg.getcol %arg0 @orders::@o_custkey : i32
      %16 = db.compare eq %14 : i32, %15 : i32
      %17 = relalg.getcol %arg0 @lineitem::@l_orderkey : i32
      %18 = relalg.getcol %arg0 @orders::@o_orderkey : i32
      %19 = db.compare eq %17 : i32, %18 : i32
      %20 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %21 = db.constant("1995-03-15") : !db.date<day>
      %22 = db.compare lt %20 : !db.date<day>, %21 : !db.date<day>
      %23 = relalg.getcol %arg0 @lineitem::@l_shipdate : !db.date<day>
      %24 = db.constant("1995-03-15") : !db.date<day>
      %25 = db.compare gt %23 : !db.date<day>, %24 : !db.date<day>
      %26 = db.and %13, %16, %19, %22, %25 : i1, i1, i1, i1, i1
      relalg.return %26 : i1
    }
    %6 = relalg.map %5 computes : [@map0::@tmp_attr1({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %11 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %12 = db.constant(1 : i32) : !db.decimal<15, 2>
      %13 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %14 = db.sub %12 : !db.decimal<15, 2>, %13 : !db.decimal<15, 2>
      %15 = db.mul %11 : !db.decimal<15, 2>, %14 : !db.decimal<15, 2>
      relalg.return %15 : !db.decimal<30, 4>
    }
    %7 = relalg.aggregation %6 [@lineitem::@l_orderkey,@orders::@o_orderdate,@orders::@o_shippriority] computes : [@aggr0::@tmp_attr0({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %11 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : !db.decimal<30, 4>
      relalg.return %11 : !db.decimal<30, 4>
    }
    %8 = relalg.sort %7 [(@aggr0::@tmp_attr0,desc),(@orders::@o_orderdate,asc)]
    %9 = relalg.limit 10 %8
    %10 = relalg.materialize %9 [@lineitem::@l_orderkey,@aggr0::@tmp_attr0,@orders::@o_orderdate,@orders::@o_shippriority] => ["l_orderkey", "revenue", "o_orderdate", "o_shippriority"] : !dsa.table
    return %10 : !dsa.table
  }
}
