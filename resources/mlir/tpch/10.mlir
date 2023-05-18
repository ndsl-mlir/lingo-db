module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "customer"} columns: {c_acctbal => @customer::@c_acctbal({type = !db.decimal<15, 2>}), c_address => @customer::@c_address({type = !db.string}), c_comment => @customer::@c_comment({type = !db.string}), c_custkey => @customer::@c_custkey({type = i32}), c_mktsegment => @customer::@c_mktsegment({type = !db.string}), c_name => @customer::@c_name({type = !db.string}), c_nationkey => @customer::@c_nationkey({type = i32}), c_phone => @customer::@c_phone({type = !db.string})}
    %1 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation::@n_name({type = !db.string}), n_nationkey => @nation::@n_nationkey({type = i32}), n_regionkey => @nation::@n_regionkey({type = i32})}
    %6 = relalg.crossproduct %4, %5
    %7 = relalg.selection %6 (%arg0: !relalg.tuple){
      %13 = relalg.getcol %arg0 @customer::@c_custkey : i32
      %14 = relalg.getcol %arg0 @orders::@o_custkey : i32
      %15 = db.compare eq %13 : i32, %14 : i32
      %16 = relalg.getcol %arg0 @lineitem::@l_orderkey : i32
      %17 = relalg.getcol %arg0 @orders::@o_orderkey : i32
      %18 = db.compare eq %16 : i32, %17 : i32
      %19 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %20 = db.constant("1993-10-01") : !db.date<day>
      %21 = db.compare gte %19 : !db.date<day>, %20 : !db.date<day>
      %22 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %23 = db.constant("1994-01-01") : !db.date<day>
      %24 = db.compare lt %22 : !db.date<day>, %23 : !db.date<day>
      %25 = relalg.getcol %arg0 @lineitem::@l_returnflag : !db.char<1>
      %26 = db.constant("R") : !db.char<1>
      %27 = db.compare eq %25 : !db.char<1>, %26 : !db.char<1>
      %28 = relalg.getcol %arg0 @customer::@c_nationkey : i32
      %29 = relalg.getcol %arg0 @nation::@n_nationkey : i32
      %30 = db.compare eq %28 : i32, %29 : i32
      %31 = db.and %15, %18, %21, %24, %27, %30 : i1, i1, i1, i1, i1, i1
      relalg.return %31 : i1
    }
    %8 = relalg.map %7 computes : [@map0::@tmp_attr1({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %13 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %14 = db.constant(1 : i32) : !db.decimal<15, 2>
      %15 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %16 = db.sub %14 : !db.decimal<15, 2>, %15 : !db.decimal<15, 2>
      %17 = db.mul %13 : !db.decimal<15, 2>, %16 : !db.decimal<15, 2>
      relalg.return %17 : !db.decimal<30, 4>
    }
    %9 = relalg.aggregation %8 [@customer::@c_custkey,@customer::@c_name,@customer::@c_acctbal,@customer::@c_phone,@nation::@n_name,@customer::@c_address,@customer::@c_comment] computes : [@aggr0::@tmp_attr0({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %13 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : !db.decimal<30, 4>
      relalg.return %13 : !db.decimal<30, 4>
    }
    %10 = relalg.sort %9 [(@aggr0::@tmp_attr0,desc)]
    %11 = relalg.limit 20 %10
    %12 = relalg.materialize %11 [@customer::@c_custkey,@customer::@c_name,@aggr0::@tmp_attr0,@customer::@c_acctbal,@nation::@n_name,@customer::@c_address,@customer::@c_phone,@customer::@c_comment] => ["c_custkey", "c_name", "revenue", "c_acctbal", "n_name", "c_address", "c_phone", "c_comment"] : !dsa.table
    return %12 : !dsa.table
  }
}
