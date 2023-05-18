module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %1 = relalg.basetable  {table_identifier = "part"} columns: {p_brand => @part::@p_brand({type = !db.string}), p_comment => @part::@p_comment({type = !db.string}), p_container => @part::@p_container({type = !db.string}), p_mfgr => @part::@p_mfgr({type = !db.string}), p_name => @part::@p_name({type = !db.string}), p_partkey => @part::@p_partkey({type = i32}), p_retailprice => @part::@p_retailprice({type = !db.decimal<15, 2>}), p_size => @part::@p_size({type = i32}), p_type => @part::@p_type({type = !db.string})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.selection %2 (%arg0: !relalg.tuple){
      %8 = relalg.getcol %arg0 @lineitem::@l_partkey : i32
      %9 = relalg.getcol %arg0 @part::@p_partkey : i32
      %10 = db.compare eq %8 : i32, %9 : i32
      %11 = relalg.getcol %arg0 @lineitem::@l_shipdate : !db.date<day>
      %12 = db.constant("1995-09-01") : !db.date<day>
      %13 = db.compare gte %11 : !db.date<day>, %12 : !db.date<day>
      %14 = relalg.getcol %arg0 @lineitem::@l_shipdate : !db.date<day>
      %15 = db.constant("1995-10-01") : !db.date<day>
      %16 = db.compare lt %14 : !db.date<day>, %15 : !db.date<day>
      %17 = db.and %10, %13, %16 : i1, i1, i1
      relalg.return %17 : i1
    }
    %4 = relalg.map %3 computes : [@map0::@tmp_attr3({type = !db.decimal<30, 4>}),@map0::@tmp_attr1({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %8 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %9 = db.constant(1 : i32) : !db.decimal<15, 2>
      %10 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %11 = db.sub %9 : !db.decimal<15, 2>, %10 : !db.decimal<15, 2>
      %12 = db.mul %8 : !db.decimal<15, 2>, %11 : !db.decimal<15, 2>
      %13 = relalg.getcol %arg0 @part::@p_type : !db.string
      %14 = db.constant("PROMO%") : !db.string
      %15 = db.runtime_call "Like"(%13, %14) : (!db.string, !db.string) -> i1
      %16 = db.derive_truth %15 : i1
      %17 = scf.if %16 -> (!db.decimal<30, 4>) {
        %18 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
        %19 = db.constant(1 : i32) : !db.decimal<15, 2>
        %20 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
        %21 = db.sub %19 : !db.decimal<15, 2>, %20 : !db.decimal<15, 2>
        %22 = db.mul %18 : !db.decimal<15, 2>, %21 : !db.decimal<15, 2>
        scf.yield %22 : !db.decimal<30, 4>
      } else {
        %18 = db.constant(0 : i32) : !db.decimal<30, 4>
        scf.yield %18 : !db.decimal<30, 4>
      }
      relalg.return %12, %17 : !db.decimal<30, 4>, !db.decimal<30, 4>
    }
    %5 = relalg.aggregation %4 [] computes : [@aggr0::@tmp_attr2({type = !db.nullable<!db.decimal<30, 4>>}),@aggr0::@tmp_attr0({type = !db.nullable<!db.decimal<30, 4>>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %8 = relalg.aggrfn sum @map0::@tmp_attr3 %arg0 : !db.nullable<!db.decimal<30, 4>>
      %9 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : !db.nullable<!db.decimal<30, 4>>
      relalg.return %8, %9 : !db.nullable<!db.decimal<30, 4>>, !db.nullable<!db.decimal<30, 4>>
    }
    %6 = relalg.map %5 computes : [@map1::@tmp_attr4({type = !db.nullable<!db.decimal<35, 6>>})] (%arg0: !relalg.tuple){
      %8 = db.constant("100.00") : !db.decimal<5, 2>
      %9 = relalg.getcol %arg0 @aggr0::@tmp_attr0 : !db.nullable<!db.decimal<30, 4>>
      %10 = db.mul %8 : !db.decimal<5, 2>, %9 : !db.nullable<!db.decimal<30, 4>>
      %11 = relalg.getcol %arg0 @aggr0::@tmp_attr2 : !db.nullable<!db.decimal<30, 4>>
      %12 = db.cast %11 : !db.nullable<!db.decimal<30, 4>> -> !db.nullable<!db.decimal<35, 6>>
      %13 = db.div %10 : !db.nullable<!db.decimal<35, 6>>, %12 : !db.nullable<!db.decimal<35, 6>>
      relalg.return %13 : !db.nullable<!db.decimal<35, 6>>
    }
    %7 = relalg.materialize %6 [@map1::@tmp_attr4] => ["promo_revenue"] : !dsa.table
    return %7 : !dsa.table
  }
}
