module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "part"} columns: {p_brand => @part::@p_brand({type = !db.string}), p_comment => @part::@p_comment({type = !db.string}), p_container => @part::@p_container({type = !db.string}), p_mfgr => @part::@p_mfgr({type = !db.string}), p_name => @part::@p_name({type = !db.string}), p_partkey => @part::@p_partkey({type = i32}), p_retailprice => @part::@p_retailprice({type = !db.decimal<15, 2>}), p_size => @part::@p_size({type = i32}), p_type => @part::@p_type({type = !db.string})}
    %1 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.basetable  {table_identifier = "partsupp"} columns: {ps_availqty => @partsupp::@ps_availqty({type = i32}), ps_comment => @partsupp::@ps_comment({type = !db.string}), ps_partkey => @partsupp::@ps_partkey({type = i32}), ps_suppkey => @partsupp::@ps_suppkey({type = i32}), ps_supplycost => @partsupp::@ps_supplycost({type = !db.decimal<15, 2>})}
    %6 = relalg.crossproduct %4, %5
    %7 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %8 = relalg.crossproduct %6, %7
    %9 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation::@n_name({type = !db.string}), n_nationkey => @nation::@n_nationkey({type = i32}), n_regionkey => @nation::@n_regionkey({type = i32})}
    %10 = relalg.crossproduct %8, %9
    %11 = relalg.selection %10 (%arg0: !relalg.tuple){
      %16 = relalg.getcol %arg0 @supplier::@s_suppkey : i32
      %17 = relalg.getcol %arg0 @lineitem::@l_suppkey : i32
      %18 = db.compare eq %16 : i32, %17 : i32
      %19 = relalg.getcol %arg0 @partsupp::@ps_suppkey : i32
      %20 = relalg.getcol %arg0 @lineitem::@l_suppkey : i32
      %21 = db.compare eq %19 : i32, %20 : i32
      %22 = relalg.getcol %arg0 @partsupp::@ps_partkey : i32
      %23 = relalg.getcol %arg0 @lineitem::@l_partkey : i32
      %24 = db.compare eq %22 : i32, %23 : i32
      %25 = relalg.getcol %arg0 @part::@p_partkey : i32
      %26 = relalg.getcol %arg0 @lineitem::@l_partkey : i32
      %27 = db.compare eq %25 : i32, %26 : i32
      %28 = relalg.getcol %arg0 @orders::@o_orderkey : i32
      %29 = relalg.getcol %arg0 @lineitem::@l_orderkey : i32
      %30 = db.compare eq %28 : i32, %29 : i32
      %31 = relalg.getcol %arg0 @supplier::@s_nationkey : i32
      %32 = relalg.getcol %arg0 @nation::@n_nationkey : i32
      %33 = db.compare eq %31 : i32, %32 : i32
      %34 = relalg.getcol %arg0 @part::@p_name : !db.string
      %35 = db.constant("%green%") : !db.string
      %36 = db.runtime_call "Like"(%34, %35) : (!db.string, !db.string) -> i1
      %37 = db.and %18, %21, %24, %27, %30, %33, %36 : i1, i1, i1, i1, i1, i1, i1
      relalg.return %37 : i1
    }
    %12 = relalg.map %11 computes : [@map0::@tmp_attr1({type = !db.decimal<30, 4>}),@map0::@tmp_attr0({type = i64})] (%arg0: !relalg.tuple){
      %16 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %17 = db.constant(1 : i32) : !db.decimal<15, 2>
      %18 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %19 = db.sub %17 : !db.decimal<15, 2>, %18 : !db.decimal<15, 2>
      %20 = db.mul %16 : !db.decimal<15, 2>, %19 : !db.decimal<15, 2>
      %21 = relalg.getcol %arg0 @partsupp::@ps_supplycost : !db.decimal<15, 2>
      %22 = relalg.getcol %arg0 @lineitem::@l_quantity : !db.decimal<15, 2>
      %23 = db.mul %21 : !db.decimal<15, 2>, %22 : !db.decimal<15, 2>
      %24 = db.sub %20 : !db.decimal<30, 4>, %23 : !db.decimal<30, 4>
      %25 = db.constant("year") : !db.char<4>
      %26 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %27 = db.runtime_call "ExtractFromDate"(%25, %26) : (!db.char<4>, !db.date<day>) -> i64
      relalg.return %24, %27 : !db.decimal<30, 4>, i64
    }
    %13 = relalg.aggregation %12 [@nation::@n_name,@map0::@tmp_attr0] computes : [@aggr0::@tmp_attr2({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %16 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : !db.decimal<30, 4>
      relalg.return %16 : !db.decimal<30, 4>
    }
    %14 = relalg.sort %13 [(@nation::@n_name,asc),(@map0::@tmp_attr0,desc)]
    %15 = relalg.materialize %14 [@nation::@n_name,@map0::@tmp_attr0,@aggr0::@tmp_attr2] => ["nation", "o_year", "sum_profit"] : !dsa.table
    return %15 : !dsa.table
  }
}
