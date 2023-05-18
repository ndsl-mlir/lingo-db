module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %1 = relalg.selection %0 (%arg0: !relalg.tuple){
      %9 = relalg.getcol %arg0 @lineitem::@l_shipdate : !db.date<day>
      %10 = db.constant("1996-01-01") : !db.date<day>
      %11 = db.compare gte %9 : !db.date<day>, %10 : !db.date<day>
      %12 = relalg.getcol %arg0 @lineitem::@l_shipdate : !db.date<day>
      %13 = db.constant("1996-04-01") : !db.date<day>
      %14 = db.compare lt %12 : !db.date<day>, %13 : !db.date<day>
      %15 = db.and %11, %14 : i1, i1
      relalg.return %15 : i1
    }
    %2 = relalg.map %1 computes : [@map0::@tmp_attr1({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %9 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %10 = db.constant(1 : i32) : !db.decimal<15, 2>
      %11 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %12 = db.sub %10 : !db.decimal<15, 2>, %11 : !db.decimal<15, 2>
      %13 = db.mul %9 : !db.decimal<15, 2>, %12 : !db.decimal<15, 2>
      relalg.return %13 : !db.decimal<30, 4>
    }
    %3 = relalg.aggregation %2 [@lineitem::@l_suppkey] computes : [@aggr0::@tmp_attr0({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %9 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : !db.decimal<30, 4>
      relalg.return %9 : !db.decimal<30, 4>
    }
    %4 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
    %5 = relalg.crossproduct %4, %3
    %6 = relalg.selection %5 (%arg0: !relalg.tuple){
      %9 = relalg.getcol %arg0 @supplier::@s_suppkey : i32
      %10 = relalg.getcol %arg0 @lineitem::@l_suppkey : i32
      %11 = db.compare eq %9 : i32, %10 : i32
      %12 = relalg.getcol %arg0 @aggr0::@tmp_attr0 : !db.decimal<30, 4>
      %13 = relalg.aggregation %3 [] computes : [@aggr1::@tmp_attr2({type = !db.nullable<!db.decimal<30, 4>>})] (%arg1: !relalg.tuplestream,%arg2: !relalg.tuple){
        %17 = relalg.aggrfn max @aggr0::@tmp_attr0 %arg1 : !db.nullable<!db.decimal<30, 4>>
        relalg.return %17 : !db.nullable<!db.decimal<30, 4>>
      }
      %14 = relalg.getscalar @aggr1::@tmp_attr2 %13 : !db.nullable<!db.decimal<30, 4>>
      %15 = db.compare eq %12 : !db.decimal<30, 4>, %14 : !db.nullable<!db.decimal<30, 4>>
      %16 = db.and %11, %15 : i1, !db.nullable<i1>
      relalg.return %16 : !db.nullable<i1>
    }
    %7 = relalg.sort %6 [(@supplier::@s_suppkey,asc)]
    %8 = relalg.materialize %7 [@supplier::@s_suppkey,@supplier::@s_name,@supplier::@s_address,@supplier::@s_phone,@aggr0::@tmp_attr0] => ["s_suppkey", "s_name", "s_address", "s_phone", "total_revenue"] : !dsa.table
    return %8 : !dsa.table
  }
}
