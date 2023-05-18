module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %1 = relalg.selection %0 (%arg0: !relalg.tuple){
      %6 = relalg.getcol %arg0 @lineitem::@l_shipdate : !db.date<day>
      %7 = db.constant("1998-12-01") : !db.date<day>
      %8 = db.constant("90days") : !db.interval<daytime>
      %9 = db.runtime_call "DateSubtract"(%7, %8) : (!db.date<day>, !db.interval<daytime>) -> !db.date<day>
      %10 = db.compare lte %6 : !db.date<day>, %9 : !db.date<day>
      relalg.return %10 : i1
    }
    %2 = relalg.map %1 computes : [@map0::@tmp_attr5({type = !db.decimal<45, 6>}),@map0::@tmp_attr3({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %6 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %7 = db.constant(1 : i32) : !db.decimal<15, 2>
      %8 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %9 = db.sub %7 : !db.decimal<15, 2>, %8 : !db.decimal<15, 2>
      %10 = db.mul %6 : !db.decimal<15, 2>, %9 : !db.decimal<15, 2>
      %11 = db.constant(1 : i32) : !db.decimal<15, 2>
      %12 = relalg.getcol %arg0 @lineitem::@l_tax : !db.decimal<15, 2>
      %13 = db.add %11 : !db.decimal<15, 2>, %12 : !db.decimal<15, 2>
      %14 = db.mul %10 : !db.decimal<30, 4>, %13 : !db.decimal<15, 2>
      %15 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %16 = db.constant(1 : i32) : !db.decimal<15, 2>
      %17 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %18 = db.sub %16 : !db.decimal<15, 2>, %17 : !db.decimal<15, 2>
      %19 = db.mul %15 : !db.decimal<15, 2>, %18 : !db.decimal<15, 2>
      relalg.return %14, %19 : !db.decimal<45, 6>, !db.decimal<30, 4>
    }
    %3 = relalg.aggregation %2 [@lineitem::@l_returnflag,@lineitem::@l_linestatus] computes : [@aggr0::@tmp_attr7({type = !db.decimal<15, 2>}),@aggr0::@tmp_attr6({type = !db.decimal<15, 2>}),@aggr0::@tmp_attr8({type = !db.decimal<15, 2>}),@aggr0::@tmp_attr4({type = !db.decimal<45, 6>}),@aggr0::@tmp_attr2({type = !db.decimal<30, 4>}),@aggr0::@tmp_attr1({type = !db.decimal<15, 2>}),@aggr0::@tmp_attr9({type = i64}),@aggr0::@tmp_attr0({type = !db.decimal<15, 2>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %6 = relalg.aggrfn avg @lineitem::@l_extendedprice %arg0 : !db.decimal<15, 2>
      %7 = relalg.aggrfn avg @lineitem::@l_quantity %arg0 : !db.decimal<15, 2>
      %8 = relalg.aggrfn avg @lineitem::@l_discount %arg0 : !db.decimal<15, 2>
      %9 = relalg.aggrfn sum @map0::@tmp_attr5 %arg0 : !db.decimal<45, 6>
      %10 = relalg.aggrfn sum @map0::@tmp_attr3 %arg0 : !db.decimal<30, 4>
      %11 = relalg.aggrfn sum @lineitem::@l_extendedprice %arg0 : !db.decimal<15, 2>
      %12 = relalg.count %arg0
      %13 = relalg.aggrfn sum @lineitem::@l_quantity %arg0 : !db.decimal<15, 2>
      relalg.return %6, %7, %8, %9, %10, %11, %12, %13 : !db.decimal<15, 2>, !db.decimal<15, 2>, !db.decimal<15, 2>, !db.decimal<45, 6>, !db.decimal<30, 4>, !db.decimal<15, 2>, i64, !db.decimal<15, 2>
    }
    %4 = relalg.sort %3 [(@lineitem::@l_returnflag,asc),(@lineitem::@l_linestatus,asc)]
    %5 = relalg.materialize %4 [@lineitem::@l_returnflag,@lineitem::@l_linestatus,@aggr0::@tmp_attr0,@aggr0::@tmp_attr1,@aggr0::@tmp_attr2,@aggr0::@tmp_attr4,@aggr0::@tmp_attr6,@aggr0::@tmp_attr7,@aggr0::@tmp_attr8,@aggr0::@tmp_attr9] => ["l_returnflag", "l_linestatus", "sum_qty", "sum_base_price", "sum_disc_price", "sum_charge", "avg_qty", "avg_price", "avg_disc", "count_order"] : !dsa.table
    return %5 : !dsa.table
  }
}
