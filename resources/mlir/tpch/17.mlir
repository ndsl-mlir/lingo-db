module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %1 = relalg.basetable  {table_identifier = "part"} columns: {p_brand => @part::@p_brand({type = !db.string}), p_comment => @part::@p_comment({type = !db.string}), p_container => @part::@p_container({type = !db.string}), p_mfgr => @part::@p_mfgr({type = !db.string}), p_name => @part::@p_name({type = !db.string}), p_partkey => @part::@p_partkey({type = i32}), p_retailprice => @part::@p_retailprice({type = !db.decimal<15, 2>}), p_size => @part::@p_size({type = i32}), p_type => @part::@p_type({type = !db.string})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.selection %2 (%arg0: !relalg.tuple){
      %7 = relalg.getcol %arg0 @part::@p_partkey : i32
      %8 = relalg.getcol %arg0 @lineitem::@l_partkey : i32
      %9 = db.compare eq %7 : i32, %8 : i32
      %10 = relalg.getcol %arg0 @part::@p_brand : !db.string
      %11 = db.constant("Brand#23") : !db.string
      %12 = db.compare eq %10 : !db.string, %11 : !db.string
      %13 = relalg.getcol %arg0 @part::@p_container : !db.string
      %14 = db.constant("MED BOX") : !db.string
      %15 = db.compare eq %13 : !db.string, %14 : !db.string
      %16 = relalg.getcol %arg0 @lineitem::@l_quantity : !db.decimal<15, 2>
      %17 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem1::@l_comment({type = !db.string}), l_commitdate => @lineitem1::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem1::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem1::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem1::@l_linenumber({type = i32}), l_linestatus => @lineitem1::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem1::@l_orderkey({type = i32}), l_partkey => @lineitem1::@l_partkey({type = i32}), l_quantity => @lineitem1::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem1::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem1::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem1::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem1::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem1::@l_shipmode({type = !db.string}), l_suppkey => @lineitem1::@l_suppkey({type = i32}), l_tax => @lineitem1::@l_tax({type = !db.decimal<15, 2>})}
      %18 = relalg.selection %17 (%arg1: !relalg.tuple){
        %25 = relalg.getcol %arg1 @lineitem1::@l_partkey : i32
        %26 = relalg.getcol %arg1 @part::@p_partkey : i32
        %27 = db.compare eq %25 : i32, %26 : i32
        relalg.return %27 : i1
      }
      %19 = relalg.aggregation %18 [] computes : [@aggr0::@tmp_attr0({type = !db.nullable<!db.decimal<15, 2>>})] (%arg1: !relalg.tuplestream,%arg2: !relalg.tuple){
        %25 = relalg.aggrfn avg @lineitem1::@l_quantity %arg1 : !db.nullable<!db.decimal<15, 2>>
        relalg.return %25 : !db.nullable<!db.decimal<15, 2>>
      }
      %20 = relalg.map %19 computes : [@map0::@tmp_attr1({type = !db.nullable<!db.decimal<17, 3>>})] (%arg1: !relalg.tuple){
        %25 = db.constant("0.2") : !db.decimal<2, 1>
        %26 = relalg.getcol %arg1 @aggr0::@tmp_attr0 : !db.nullable<!db.decimal<15, 2>>
        %27 = db.mul %25 : !db.decimal<2, 1>, %26 : !db.nullable<!db.decimal<15, 2>>
        relalg.return %27 : !db.nullable<!db.decimal<17, 3>>
      }
      %21 = relalg.getscalar @map0::@tmp_attr1 %20 : !db.nullable<!db.decimal<17, 3>>
      %22 = db.cast %16 : !db.decimal<15, 2> -> !db.decimal<17, 3>
      %23 = db.compare lt %22 : !db.decimal<17, 3>, %21 : !db.nullable<!db.decimal<17, 3>>
      %24 = db.and %9, %12, %15, %23 : i1, i1, i1, !db.nullable<i1>
      relalg.return %24 : !db.nullable<i1>
    }
    %4 = relalg.aggregation %3 [] computes : [@aggr1::@tmp_attr2({type = !db.nullable<!db.decimal<15, 2>>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %7 = relalg.aggrfn sum @lineitem::@l_extendedprice %arg0 : !db.nullable<!db.decimal<15, 2>>
      relalg.return %7 : !db.nullable<!db.decimal<15, 2>>
    }
    %5 = relalg.map %4 computes : [@map1::@tmp_attr3({type = !db.nullable<!db.decimal<15, 2>>})] (%arg0: !relalg.tuple){
      %7 = relalg.getcol %arg0 @aggr1::@tmp_attr2 : !db.nullable<!db.decimal<15, 2>>
      %8 = db.constant("7.0") : !db.decimal<15, 2>
      %9 = db.div %7 : !db.nullable<!db.decimal<15, 2>>, %8 : !db.decimal<15, 2>
      relalg.return %9 : !db.nullable<!db.decimal<15, 2>>
    }
    %6 = relalg.materialize %5 [@map1::@tmp_attr3] => ["avg_yearly"] : !dsa.table
    return %6 : !dsa.table
  }
}
