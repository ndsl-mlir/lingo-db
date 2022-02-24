//RUN: db-run-query %s %S/../../../resources/data/tpch | FileCheck %s
//CHECK: |                     cntrycode  |                       numcust  |                    totacctbal  |
//CHECK: ----------------------------------------------------------------------------------------------------
//CHECK: |                          "13"  |                            94  |                     714035.05  |
//CHECK: |                          "17"  |                            96  |                     722560.15  |
//CHECK: |                          "18"  |                            99  |                     738012.52  |
//CHECK: |                          "23"  |                            93  |                     708285.25  |
//CHECK: |                          "29"  |                            85  |                     632693.46  |
//CHECK: |                          "30"  |                            87  |                     646748.02  |
//CHECK: |                          "31"  |                            87  |                     647372.50  |
module @querymodule{
    func @main ()  -> !db.table{
        %1 = relalg.basetable @customer { table_identifier="customer", rows=15000 , pkey=["c_custkey"]} columns: {c_custkey => @c_custkey({type=i32}),
            c_name => @c_name({type=!db.string}),
            c_address => @c_address({type=!db.string}),
            c_nationkey => @c_nationkey({type=i32}),
            c_phone => @c_phone({type=!db.string}),
            c_acctbal => @c_acctbal({type=!db.decimal<15,2>}),
            c_mktsegment => @c_mktsegment({type=!db.string}),
            c_comment => @c_comment({type=!db.string})
        }
        %3 = relalg.selection %1(%2: !relalg.tuple) {
            %c_phone2 = relalg.getattr %2 @customer::@c_phone : !db.string
            %4 = db.substr %c_phone2[1:2] : !db.string
            %5 = db.constant ("13") :!db.string
            %6 = db.compare eq %4 : !db.string,%5 : !db.string
            %7 = db.constant ("31") :!db.string
            %8 = db.compare eq %4 : !db.string,%7 : !db.string
            %9 = db.constant ("23") :!db.string
            %10 = db.compare eq %4 : !db.string,%9 : !db.string
            %11 = db.constant ("29") :!db.string
            %12 = db.compare eq %4 : !db.string,%11 : !db.string
            %13 = db.constant ("30") :!db.string
            %14 = db.compare eq %4 : !db.string,%13 : !db.string
            %15 = db.constant ("18") :!db.string
            %16 = db.compare eq %4 : !db.string,%15 : !db.string
            %17 = db.constant ("17") :!db.string
            %18 = db.compare eq %4 : !db.string,%17 : !db.string
            %19 = db.or %6 : i1,%8 : i1,%10 : i1,%12 : i1,%14 : i1,%16 : i1,%18 : i1
            %20 = relalg.getattr %2 @customer::@c_acctbal : !db.decimal<15,2>
            %21 = relalg.basetable @customer1 { table_identifier="customer", rows=15000 , pkey=["c_custkey"]} columns: {c_custkey => @c_custkey({type=i32}),
                c_name => @c_name({type=!db.string}),
                c_address => @c_address({type=!db.string}),
                c_nationkey => @c_nationkey({type=i32}),
                c_phone => @c_phone({type=!db.string}),
                c_acctbal => @c_acctbal({type=!db.decimal<15,2>}),
                c_mktsegment => @c_mktsegment({type=!db.string}),
                c_comment => @c_comment({type=!db.string})
            }
            %23 = relalg.selection %21(%22: !relalg.tuple) {
                %24 = relalg.getattr %22 @customer1::@c_acctbal : !db.decimal<15,2>
                %25 = db.constant ("0.0") :!db.decimal<15,2>
                %26 = db.compare gt %24 : !db.decimal<15,2>,%25 : !db.decimal<15,2>
                %c_phone = relalg.getattr %22 @customer1::@c_phone : !db.string
                %27 = db.substr %c_phone[1:2] : !db.string
                %28 = db.constant ("13") :!db.string
                %29 = db.compare eq %27 : !db.string,%28 : !db.string
                %30 = db.constant ("31") :!db.string
                %31 = db.compare eq %27 : !db.string,%30 : !db.string
                %32 = db.constant ("23") :!db.string
                %33 = db.compare eq %27 : !db.string,%32 : !db.string
                %34 = db.constant ("29") :!db.string
                %35 = db.compare eq %27 : !db.string,%34 : !db.string
                %36 = db.constant ("30") :!db.string
                %37 = db.compare eq %27 : !db.string,%36 : !db.string
                %38 = db.constant ("18") :!db.string
                %39 = db.compare eq %27 : !db.string,%38 : !db.string
                %40 = db.constant ("17") :!db.string
                %41 = db.compare eq %27 : !db.string,%40 : !db.string
                %42 = db.or %29 : i1,%31 : i1,%33 : i1,%35 : i1,%37 : i1,%39 : i1,%41 : i1
                %43 = db.and %26 : i1,%42 : i1
                relalg.return %43 : i1
            }
            %45 = relalg.aggregation @aggr1 %23 [] (%44 : !relalg.tuplestream,%tuple : !relalg.tuple) {
                %46 = relalg.aggrfn avg @customer1::@c_acctbal %44 : !db.nullable<!db.decimal<15,2>>
                relalg.addattr %tuple, @aggfmname1({type=!db.nullable<!db.decimal<15,2>>}) %46
                relalg.return
            }
            %47 = relalg.getscalar @aggr1::@aggfmname1 %45 : !db.nullable<!db.decimal<15,2>>
            %48 = db.compare gt %20 : !db.decimal<15,2>,%47 : !db.nullable<!db.decimal<15,2>>
            %49 = relalg.basetable @orders { table_identifier="orders", rows=150000 , pkey=["o_orderkey"]} columns: {o_orderkey => @o_orderkey({type=i32}),
                o_custkey => @o_custkey({type=i32}),
                o_orderstatus => @o_orderstatus({type=!db.char<1>}),
                o_totalprice => @o_totalprice({type=!db.decimal<15,2>}),
                o_orderdate => @o_orderdate({type=!db.date<day>}),
                o_orderpriority => @o_orderpriority({type=!db.string}),
                o_clerk => @o_clerk({type=!db.string}),
                o_shippriority => @o_shippriority({type=i32}),
                o_comment => @o_comment({type=!db.string})
            }
            %51 = relalg.selection %49(%50: !relalg.tuple) {
                %52 = relalg.getattr %50 @orders::@o_custkey : i32
                %53 = relalg.getattr %2 @customer::@c_custkey : i32
                %54 = db.compare eq %52 : i32,%53 : i32
                relalg.return %54 : i1
            }
            %55 = relalg.exists%51
            %56 = db.not %55 : i1
            %57 = db.and %19 : i1,%48 : !db.nullable<i1> ,%56 : i1
            relalg.return %57 : !db.nullable<i1>
        }
        %mapped = relalg.map @map %3 (%maparg: !relalg.tuple) {
            %c_phone = relalg.getattr %maparg @customer::@c_phone : !db.string
            %cntrycode = db.substr %c_phone[1:2] : !db.string
        	%tpl=relalg.addattr %maparg, @cntrycode({type = !db.string}) %cntrycode
        	relalg.return %tpl : !relalg.tuple
        }
        %59 = relalg.aggregation @aggr4 %mapped [@map::@cntrycode] (%58 : !relalg.tuplestream, %tuple : !relalg.tuple) {
            %60 = relalg.count %58
            relalg.addattr %tuple, @aggfmname1({type=i64}) %60
            %61 = relalg.aggrfn sum @customer::@c_acctbal %58 : !db.decimal<15,2>
            relalg.addattr %tuple, @aggfmname2({type=!db.decimal<15,2>}) %61
            relalg.return
        }
        %62 = relalg.sort %59 [(@map::@cntrycode,asc)]
        %63 = relalg.materialize %62 [@map::@cntrycode,@aggr4::@aggfmname1,@aggr4::@aggfmname2] => ["cntrycode","numcust","totacctbal"] : !db.table
        return %63 : !db.table
    }
}


