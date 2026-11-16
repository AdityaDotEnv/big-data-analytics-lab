const dbName = process.env.LAB_DB_NAME || "bcs714d_lab_aggregation";
const lab = db.getSiblingDB(dbName);
const customers = lab.customers;
customers.deleteMany({labRun:"aggregation-demo"});
customers.insertMany([
  {CustID:"C123", AccBal:500, AccType:"S", labRun:"aggregation-demo"},
  {CustID:"C123", AccBal:900, AccType:"S", labRun:"aggregation-demo"},
  {CustID:"C111", AccBal:1200, AccType:"S", labRun:"aggregation-demo"},
  {CustID:"C123", AccBal:1500, AccType:"C", labRun:"aggregation-demo"}
]);

print("\nInput customer documents:");
customers.find({labRun:"aggregation-demo"}).forEach(printjson);

print("\nFilter AccType S, group by CustID, sum AccBal, retain totals > 1200:");
customers.aggregate([
  {$match: {AccType:"S", labRun:"aggregation-demo"}},
  {$group: {_id:"$CustID", TotAccBal: {$sum:"$AccBal"}}},
  {$match: {TotAccBal: {$gt:1200}}},
  {$sort: {_id:1}}
]).forEach(printjson);

print("\nAverage balance by customer (S accounts):");
customers.aggregate([
  {$match: {AccType:"S", labRun:"aggregation-demo"}},
  {$group: {_id:"$CustID", AvgAccBal: {$avg:"$AccBal"}}},
  {$sort: {_id:1}}
]).forEach(printjson);
