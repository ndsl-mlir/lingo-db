module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "customer"} columns: {c_acctbal => @customer::@c_acctbal({type = !db.decimal<15, 2>}), c_address => @customer::@c_address({type = !db.string}), c_comment => @customer::@c_comment({type = !db.string}), c_custkey => @customer::@c_custkey({type = i32}), c_mktsegment => @customer::@c_mktsegment({type = !db.string}), c_name => @customer::@c_name({type = !db.string}), c_nationkey => @customer::@c_nationkey({type = i32}), c_phone => @customer::@c_phone({type = !db.string})}
    %1 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %2 = relalg.outerjoin %0, %1 (%arg0: !relalg.tuple){
      %7 = relalg.getcol %arg0 @customer::@c_custkey : i32
      %8 = relalg.getcol %arg0 @orders::@o_custkey : i32
      %9 = db.compare eq %7 : i32, %8 : i32
      %10 = relalg.getcol %arg0 @orders::@o_comment : !db.string
      %11 = db.constant("%special%requests%") : !db.string
      %12 = db.runtime_call "Like"(%10, %11) : (!db.string, !db.string) -> i1
      %13 = db.not %12 : i1
      %14 = db.and %9, %13 : i1, i1
      relalg.return %14 : i1
    }  mapping: {@oj0::@o_orderkey({type = !db.nullable<i32>})=[@orders::@o_orderkey], @oj0::@o_custkey({type = !db.nullable<i32>})=[@orders::@o_custkey], @oj0::@o_orderstatus({type = !db.nullable<!db.char<1>>})=[@orders::@o_orderstatus], @oj0::@o_totalprice({type = !db.nullable<!db.decimal<15, 2>>})=[@orders::@o_totalprice], @oj0::@o_orderdate({type = !db.nullable<!db.date<day>>})=[@orders::@o_orderdate], @oj0::@o_orderpriority({type = !db.nullable<!db.string>})=[@orders::@o_orderpriority], @oj0::@o_clerk({type = !db.nullable<!db.string>})=[@orders::@o_clerk], @oj0::@o_shippriority({type = !db.nullable<i32>})=[@orders::@o_shippriority], @oj0::@o_comment({type = !db.nullable<!db.string>})=[@orders::@o_comment]}
    %3 = relalg.aggregation %2 [@customer::@c_custkey] computes : [@aggr0::@tmp_attr0({type = i64})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %7 = relalg.aggrfn count @oj0::@o_orderkey %arg0 : i64
      relalg.return %7 : i64
    }
    %4 = relalg.aggregation %3 [@aggr0::@tmp_attr0] computes : [@aggr1::@tmp_attr1({type = i64})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %7 = relalg.count %arg0
      relalg.return %7 : i64
    }
    %5 = relalg.sort %4 [(@aggr1::@tmp_attr1,desc),(@aggr0::@tmp_attr0,desc)]
    %6 = relalg.materialize %5 [@aggr0::@tmp_attr0,@aggr1::@tmp_attr1] => ["c_count", "custdist"] : !dsa.table
    return %6 : !dsa.table
  }
}
