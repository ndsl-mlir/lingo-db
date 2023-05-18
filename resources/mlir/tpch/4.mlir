module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %1 = relalg.selection %0 (%arg0: !relalg.tuple){
      %5 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %6 = db.constant("1993-07-01") : !db.date<day>
      %7 = db.compare gte %5 : !db.date<day>, %6 : !db.date<day>
      %8 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %9 = db.constant("1993-10-01") : !db.date<day>
      %10 = db.compare lt %8 : !db.date<day>, %9 : !db.date<day>
      %11 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
      %12 = relalg.selection %11 (%arg1: !relalg.tuple){
        %15 = relalg.getcol %arg1 @lineitem::@l_orderkey : i32
        %16 = relalg.getcol %arg1 @orders::@o_orderkey : i32
        %17 = db.compare eq %15 : i32, %16 : i32
        %18 = relalg.getcol %arg1 @lineitem::@l_commitdate : !db.date<day>
        %19 = relalg.getcol %arg1 @lineitem::@l_receiptdate : !db.date<day>
        %20 = db.compare lt %18 : !db.date<day>, %19 : !db.date<day>
        %21 = db.and %17, %20 : i1, i1
        relalg.return %21 : i1
      }
      %13 = relalg.exists %12
      %14 = db.and %7, %10, %13 : i1, i1, i1
      relalg.return %14 : i1
    }
    %2 = relalg.aggregation %1 [@orders::@o_orderpriority] computes : [@aggr0::@tmp_attr0({type = i64})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %5 = relalg.count %arg0
      relalg.return %5 : i64
    }
    %3 = relalg.sort %2 [(@orders::@o_orderpriority,asc)]
    %4 = relalg.materialize %3 [@orders::@o_orderpriority,@aggr0::@tmp_attr0] => ["o_orderpriority", "order_count"] : !dsa.table
    return %4 : !dsa.table
  }
}
