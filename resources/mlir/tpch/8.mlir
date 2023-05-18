module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "part"} columns: {p_brand => @part::@p_brand({type = !db.string}), p_comment => @part::@p_comment({type = !db.string}), p_container => @part::@p_container({type = !db.string}), p_mfgr => @part::@p_mfgr({type = !db.string}), p_name => @part::@p_name({type = !db.string}), p_partkey => @part::@p_partkey({type = i32}), p_retailprice => @part::@p_retailprice({type = !db.decimal<15, 2>}), p_size => @part::@p_size({type = i32}), p_type => @part::@p_type({type = !db.string})}
    %1 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.basetable  {table_identifier = "orders"} columns: {o_clerk => @orders::@o_clerk({type = !db.string}), o_comment => @orders::@o_comment({type = !db.string}), o_custkey => @orders::@o_custkey({type = i32}), o_orderdate => @orders::@o_orderdate({type = !db.date<day>}), o_orderkey => @orders::@o_orderkey({type = i32}), o_orderpriority => @orders::@o_orderpriority({type = !db.string}), o_orderstatus => @orders::@o_orderstatus({type = !db.char<1>}), o_shippriority => @orders::@o_shippriority({type = i32}), o_totalprice => @orders::@o_totalprice({type = !db.decimal<15, 2>})}
    %6 = relalg.crossproduct %4, %5
    %7 = relalg.basetable  {table_identifier = "customer"} columns: {c_acctbal => @customer::@c_acctbal({type = !db.decimal<15, 2>}), c_address => @customer::@c_address({type = !db.string}), c_comment => @customer::@c_comment({type = !db.string}), c_custkey => @customer::@c_custkey({type = i32}), c_mktsegment => @customer::@c_mktsegment({type = !db.string}), c_name => @customer::@c_name({type = !db.string}), c_nationkey => @customer::@c_nationkey({type = i32}), c_phone => @customer::@c_phone({type = !db.string})}
    %8 = relalg.crossproduct %6, %7
    %9 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @n1_::@n_comment({type = !db.nullable<!db.string>}), n_name => @n1_::@n_name({type = !db.string}), n_nationkey => @n1_::@n_nationkey({type = i32}), n_regionkey => @n1_::@n_regionkey({type = i32})}
    %10 = relalg.crossproduct %8, %9
    %11 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @n2_::@n_comment({type = !db.nullable<!db.string>}), n_name => @n2_::@n_name({type = !db.string}), n_nationkey => @n2_::@n_nationkey({type = i32}), n_regionkey => @n2_::@n_regionkey({type = i32})}
    %12 = relalg.crossproduct %10, %11
    %13 = relalg.basetable  {table_identifier = "region"} columns: {r_comment => @region::@r_comment({type = !db.nullable<!db.string>}), r_name => @region::@r_name({type = !db.string}), r_regionkey => @region::@r_regionkey({type = i32})}
    %14 = relalg.crossproduct %12, %13
    %15 = relalg.selection %14 (%arg0: !relalg.tuple){
      %22 = relalg.getcol %arg0 @part::@p_partkey : i32
      %23 = relalg.getcol %arg0 @lineitem::@l_partkey : i32
      %24 = db.compare eq %22 : i32, %23 : i32
      %25 = relalg.getcol %arg0 @supplier::@s_suppkey : i32
      %26 = relalg.getcol %arg0 @lineitem::@l_suppkey : i32
      %27 = db.compare eq %25 : i32, %26 : i32
      %28 = relalg.getcol %arg0 @lineitem::@l_orderkey : i32
      %29 = relalg.getcol %arg0 @orders::@o_orderkey : i32
      %30 = db.compare eq %28 : i32, %29 : i32
      %31 = relalg.getcol %arg0 @orders::@o_custkey : i32
      %32 = relalg.getcol %arg0 @customer::@c_custkey : i32
      %33 = db.compare eq %31 : i32, %32 : i32
      %34 = relalg.getcol %arg0 @customer::@c_nationkey : i32
      %35 = relalg.getcol %arg0 @n1_::@n_nationkey : i32
      %36 = db.compare eq %34 : i32, %35 : i32
      %37 = relalg.getcol %arg0 @n1_::@n_regionkey : i32
      %38 = relalg.getcol %arg0 @region::@r_regionkey : i32
      %39 = db.compare eq %37 : i32, %38 : i32
      %40 = relalg.getcol %arg0 @region::@r_name : !db.string
      %41 = db.constant("AMERICA") : !db.string
      %42 = db.compare eq %40 : !db.string, %41 : !db.string
      %43 = relalg.getcol %arg0 @supplier::@s_nationkey : i32
      %44 = relalg.getcol %arg0 @n2_::@n_nationkey : i32
      %45 = db.compare eq %43 : i32, %44 : i32
      %46 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %47 = db.constant("1995-01-01") : !db.date<day>
      %48 = db.constant("1996-12-31") : !db.date<day>
      %49 = db.between %46 : !db.date<day> between %47 : !db.date<day>, %48 : !db.date<day>, lowerInclusive : true, upperInclusive : true
      %50 = relalg.getcol %arg0 @part::@p_type : !db.string
      %51 = db.constant("ECONOMY ANODIZED STEEL") : !db.string
      %52 = db.compare eq %50 : !db.string, %51 : !db.string
      %53 = db.and %24, %27, %30, %33, %36, %39, %42, %45, %49, %52 : i1, i1, i1, i1, i1, i1, i1, i1, i1, i1
      relalg.return %53 : i1
    }
    %16 = relalg.map %15 computes : [@map0::@tmp_attr1({type = !db.decimal<30, 4>}),@map0::@tmp_attr0({type = i64})] (%arg0: !relalg.tuple){
      %22 = relalg.getcol %arg0 @lineitem::@l_extendedprice : !db.decimal<15, 2>
      %23 = db.constant(1 : i32) : !db.decimal<15, 2>
      %24 = relalg.getcol %arg0 @lineitem::@l_discount : !db.decimal<15, 2>
      %25 = db.sub %23 : !db.decimal<15, 2>, %24 : !db.decimal<15, 2>
      %26 = db.mul %22 : !db.decimal<15, 2>, %25 : !db.decimal<15, 2>
      %27 = db.constant("year") : !db.char<4>
      %28 = relalg.getcol %arg0 @orders::@o_orderdate : !db.date<day>
      %29 = db.runtime_call "ExtractFromDate"(%27, %28) : (!db.char<4>, !db.date<day>) -> i64
      relalg.return %26, %29 : !db.decimal<30, 4>, i64
    }
    %17 = relalg.map %16 computes : [@map1::@tmp_attr3({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %22 = relalg.getcol %arg0 @n2_::@n_name : !db.string
      %23 = db.constant("BRAZIL") : !db.string
      %24 = db.compare eq %22 : !db.string, %23 : !db.string
      %25 = db.derive_truth %24 : i1
      %26 = scf.if %25 -> (!db.decimal<30, 4>) {
        %27 = relalg.getcol %arg0 @map0::@tmp_attr1 : !db.decimal<30, 4>
        scf.yield %27 : !db.decimal<30, 4>
      } else {
        %27 = db.constant(0 : i32) : !db.decimal<30, 4>
        scf.yield %27 : !db.decimal<30, 4>
      }
      relalg.return %26 : !db.decimal<30, 4>
    }
    %18 = relalg.aggregation %17 [@map0::@tmp_attr0] computes : [@aggr0::@tmp_attr4({type = !db.decimal<30, 4>}),@aggr0::@tmp_attr2({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %22 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : !db.decimal<30, 4>
      %23 = relalg.aggrfn sum @map1::@tmp_attr3 %arg0 : !db.decimal<30, 4>
      relalg.return %22, %23 : !db.decimal<30, 4>, !db.decimal<30, 4>
    }
    %19 = relalg.map %18 computes : [@map2::@tmp_attr5({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %22 = relalg.getcol %arg0 @aggr0::@tmp_attr2 : !db.decimal<30, 4>
      %23 = relalg.getcol %arg0 @aggr0::@tmp_attr4 : !db.decimal<30, 4>
      %24 = db.div %22 : !db.decimal<30, 4>, %23 : !db.decimal<30, 4>
      relalg.return %24 : !db.decimal<30, 4>
    }
    %20 = relalg.sort %19 [(@map0::@tmp_attr0,asc)]
    %21 = relalg.materialize %20 [@map0::@tmp_attr0,@map2::@tmp_attr5] => ["o_year", "mkt_share"] : !dsa.table
    return %21 : !dsa.table
  }
}
