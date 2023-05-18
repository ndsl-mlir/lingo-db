module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %1 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.selection %2 (%arg0: !relalg.tuple){
      %8 = relalg.getcol %arg0 @orders::@o_orderkey : i32
      %9 = relalg.getcol %arg0 @lineitem::@l_orderkey : i32
      %10 = db.compare eq %8 : i32, %9 : i32
      %11 = db.constant("MAIL") : !db.string
      %12 = db.constant("SHIP") : !db.string
      %13 = relalg.getcol %arg0 @lineitem::@l_shipmode : !db.string
      %14 = db.oneof %13 : !db.string ? %11, %12 : !db.string, !db.string
      %15 = relalg.getcol %arg0 @lineitem::@l_commitdate : !db.date<day>
      %16 = relalg.getcol %arg0 @lineitem::@l_receiptdate : !db.date<day>
      %17 = db.compare lt %15 : !db.date<day>, %16 : !db.date<day>
      %18 = relalg.getcol %arg0 @lineitem::@l_shipdate : !db.date<day>
      %19 = relalg.getcol %arg0 @lineitem::@l_commitdate : !db.date<day>
      %20 = db.compare lt %18 : !db.date<day>, %19 : !db.date<day>
      %21 = relalg.getcol %arg0 @lineitem::@l_receiptdate : !db.date<day>
      %22 = db.constant("1994-01-01") : !db.date<day>
      %23 = db.compare gte %21 : !db.date<day>, %22 : !db.date<day>
      %24 = relalg.getcol %arg0 @lineitem::@l_receiptdate : !db.date<day>
      %25 = db.constant("1995-01-01") : !db.date<day>
      %26 = db.compare lt %24 : !db.date<day>, %25 : !db.date<day>
      %27 = db.and %10, %14, %17, %20, %23, %26 : i1, i1, i1, i1, i1, i1
      relalg.return %27 : i1
    }
    %4 = relalg.map %3 computes : [@map0::@tmp_attr3({type = i32}),@map0::@tmp_attr1({type = i32})] (%arg0: !relalg.tuple){
      %8 = relalg.getcol %arg0 @orders::@o_orderpriority : !db.string
      %9 = db.constant("1-URGENT") : !db.string
      %10 = db.compare neq %8 : !db.string, %9 : !db.string
      %11 = relalg.getcol %arg0 @orders::@o_orderpriority : !db.string
      %12 = db.constant("2-HIGH") : !db.string
      %13 = db.compare neq %11 : !db.string, %12 : !db.string
      %14 = db.and %10, %13 : i1, i1
      %15 = db.derive_truth %14 : i1
      %16 = scf.if %15 -> (i32) {
        %26 = db.constant(1 : i32) : i32
        scf.yield %26 : i32
      } else {
        %26 = db.constant(0 : i32) : i32
        scf.yield %26 : i32
      }
      %17 = relalg.getcol %arg0 @orders::@o_orderpriority : !db.string
      %18 = db.constant("1-URGENT") : !db.string
      %19 = db.compare eq %17 : !db.string, %18 : !db.string
      %20 = relalg.getcol %arg0 @orders::@o_orderpriority : !db.string
      %21 = db.constant("2-HIGH") : !db.string
      %22 = db.compare eq %20 : !db.string, %21 : !db.string
      %23 = db.or %19, %22 : i1, i1
      %24 = db.derive_truth %23 : i1
      %25 = scf.if %24 -> (i32) {
        %26 = db.constant(1 : i32) : i32
        scf.yield %26 : i32
      } else {
        %26 = db.constant(0 : i32) : i32
        scf.yield %26 : i32
      }
      relalg.return %16, %25 : i32, i32
    }
    %5 = relalg.aggregation %4 [@lineitem::@l_shipmode] computes : [@aggr0::@tmp_attr2({type = i32}),@aggr0::@tmp_attr0({type = i32})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %8 = relalg.aggrfn sum @map0::@tmp_attr3 %arg0 : i32
      %9 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : i32
      relalg.return %8, %9 : i32, i32
    }
    %6 = relalg.sort %5 [(@lineitem::@l_shipmode,asc)]
    %7 = relalg.materialize %6 [@lineitem::@l_shipmode,@aggr0::@tmp_attr0,@aggr0::@tmp_attr2] => ["l_shipmode", "high_line_count", "low_line_count"] : !dsa.table
    return %7 : !dsa.table
  }
}
