module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
    %1 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation::@n_name({type = !db.string}), n_nationkey => @nation::@n_nationkey({type = i32}), n_regionkey => @nation::@n_regionkey({type = i32})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.selection %2 (%arg0: !relalg.tuple){
      %6 = relalg.basetable  {table_identifier = "partsupp"} columns: {ps_availqty => @partsupp::@ps_availqty({type = i32}), ps_comment => @partsupp::@ps_comment({type = !db.string}), ps_partkey => @partsupp::@ps_partkey({type = i32}), ps_suppkey => @partsupp::@ps_suppkey({type = i32}), ps_supplycost => @partsupp::@ps_supplycost({type = !db.decimal<15, 2>})}
      %7 = relalg.selection %6 (%arg1: !relalg.tuple){
        %17 = relalg.basetable  {table_identifier = "part"} columns: {p_brand => @part::@p_brand({type = !db.string}), p_comment => @part::@p_comment({type = !db.string}), p_container => @part::@p_container({type = !db.string}), p_mfgr => @part::@p_mfgr({type = !db.string}), p_name => @part::@p_name({type = !db.string}), p_partkey => @part::@p_partkey({type = i32}), p_retailprice => @part::@p_retailprice({type = !db.decimal<15, 2>}), p_size => @part::@p_size({type = i32}), p_type => @part::@p_type({type = !db.string})}
        %18 = relalg.selection %17 (%arg2: !relalg.tuple){
          %30 = relalg.getcol %arg2 @part::@p_name : !db.string
          %31 = db.constant("forest%") : !db.string
          %32 = db.runtime_call "Like"(%30, %31) : (!db.string, !db.string) -> i1
          relalg.return %32 : i1
        }
        %19 = relalg.selection %18 (%arg2: !relalg.tuple){
          %30 = relalg.getcol %arg2 @partsupp::@ps_partkey : i32
          %31 = relalg.getcol %arg2 @part::@p_partkey : i32
          %32 = db.compare eq %30 : i32, %31 : i32
          relalg.return %32 : i1
        }
        %20 = relalg.exists %19
        %21 = relalg.getcol %arg1 @partsupp::@ps_availqty : i32
        %22 = relalg.basetable  {table_identifier = "lineitem"} columns: {l_comment => @lineitem::@l_comment({type = !db.string}), l_commitdate => @lineitem::@l_commitdate({type = !db.date<day>}), l_discount => @lineitem::@l_discount({type = !db.decimal<15, 2>}), l_extendedprice => @lineitem::@l_extendedprice({type = !db.decimal<15, 2>}), l_linenumber => @lineitem::@l_linenumber({type = i32}), l_linestatus => @lineitem::@l_linestatus({type = !db.char<1>}), l_orderkey => @lineitem::@l_orderkey({type = i32}), l_partkey => @lineitem::@l_partkey({type = i32}), l_quantity => @lineitem::@l_quantity({type = !db.decimal<15, 2>}), l_receiptdate => @lineitem::@l_receiptdate({type = !db.date<day>}), l_returnflag => @lineitem::@l_returnflag({type = !db.char<1>}), l_shipdate => @lineitem::@l_shipdate({type = !db.date<day>}), l_shipinstruct => @lineitem::@l_shipinstruct({type = !db.string}), l_shipmode => @lineitem::@l_shipmode({type = !db.string}), l_suppkey => @lineitem::@l_suppkey({type = i32}), l_tax => @lineitem::@l_tax({type = !db.decimal<15, 2>})}
        %23 = relalg.selection %22 (%arg2: !relalg.tuple){
          %30 = relalg.getcol %arg2 @lineitem::@l_partkey : i32
          %31 = relalg.getcol %arg2 @partsupp::@ps_partkey : i32
          %32 = db.compare eq %30 : i32, %31 : i32
          %33 = relalg.getcol %arg2 @lineitem::@l_suppkey : i32
          %34 = relalg.getcol %arg2 @partsupp::@ps_suppkey : i32
          %35 = db.compare eq %33 : i32, %34 : i32
          %36 = relalg.getcol %arg2 @lineitem::@l_shipdate : !db.date<day>
          %37 = db.constant("1994-01-01") : !db.date<day>
          %38 = db.compare gte %36 : !db.date<day>, %37 : !db.date<day>
          %39 = relalg.getcol %arg2 @lineitem::@l_shipdate : !db.date<day>
          %40 = db.constant("1995-01-01") : !db.date<day>
          %41 = db.compare lt %39 : !db.date<day>, %40 : !db.date<day>
          %42 = db.and %32, %35, %38, %41 : i1, i1, i1, i1
          relalg.return %42 : i1
        }
        %24 = relalg.aggregation %23 [] computes : [@aggr0::@tmp_attr0({type = !db.nullable<!db.decimal<15, 2>>})] (%arg2: !relalg.tuplestream,%arg3: !relalg.tuple){
          %30 = relalg.aggrfn sum @lineitem::@l_quantity %arg2 : !db.nullable<!db.decimal<15, 2>>
          relalg.return %30 : !db.nullable<!db.decimal<15, 2>>
        }
        %25 = relalg.map %24 computes : [@map0::@tmp_attr1({type = !db.nullable<!db.decimal<17, 3>>})] (%arg2: !relalg.tuple){
          %30 = db.constant("0.5") : !db.decimal<2, 1>
          %31 = relalg.getcol %arg2 @aggr0::@tmp_attr0 : !db.nullable<!db.decimal<15, 2>>
          %32 = db.mul %30 : !db.decimal<2, 1>, %31 : !db.nullable<!db.decimal<15, 2>>
          relalg.return %32 : !db.nullable<!db.decimal<17, 3>>
        }
        %26 = relalg.getscalar @map0::@tmp_attr1 %25 : !db.nullable<!db.decimal<17, 3>>
        %27 = db.cast %21 : i32 -> !db.decimal<17, 3>
        %28 = db.compare gt %27 : !db.decimal<17, 3>, %26 : !db.nullable<!db.decimal<17, 3>>
        %29 = db.and %20, %28 : i1, !db.nullable<i1>
        relalg.return %29 : !db.nullable<i1>
      }
      %8 = relalg.selection %7 (%arg1: !relalg.tuple){
        %17 = relalg.getcol %arg1 @supplier::@s_suppkey : i32
        %18 = relalg.getcol %arg1 @partsupp::@ps_suppkey : i32
        %19 = db.compare eq %17 : i32, %18 : i32
        relalg.return %19 : i1
      }
      %9 = relalg.exists %8
      %10 = relalg.getcol %arg0 @supplier::@s_nationkey : i32
      %11 = relalg.getcol %arg0 @nation::@n_nationkey : i32
      %12 = db.compare eq %10 : i32, %11 : i32
      %13 = relalg.getcol %arg0 @nation::@n_name : !db.string
      %14 = db.constant("CANADA") : !db.string
      %15 = db.compare eq %13 : !db.string, %14 : !db.string
      %16 = db.and %9, %12, %15 : i1, i1, i1
      relalg.return %16 : i1
    }
    %4 = relalg.sort %3 [(@supplier::@s_name,asc)]
    %5 = relalg.materialize %4 [@supplier::@s_name,@supplier::@s_address] => ["s_name", "s_address"] : !dsa.table
    return %5 : !dsa.table
  }
}
