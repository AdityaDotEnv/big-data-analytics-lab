const dbName = process.env.LAB_DB_NAME || "bcs714d_lab_crud";
const lab = db.getSiblingDB(dbName);
print(`\nDatabase: ${dbName}`);
print("\nExisting databases:");
db.adminCommand({listDatabases: 1, nameOnly: true}).databases.forEach(x => print(` - ${x.name}`));

const students = lab.students;
students.deleteMany({labRun: "crud-demo"});
students.insertMany([
  {_id: "S101", name: "Simon", grade: "VII", hobby: "Surfing", labRun: "crud-demo"},
  {_id: "S102", name: "Aryan David", grade: "VII", hobby: "Skating", labRun: "crud-demo"},
  {_id: "S103", name: "Vamsi Bapat", grade: "VIII", hobby: "Music", labRun: "crud-demo"}
]);
print("\nInserted student documents:");
students.find({labRun: "crud-demo"}).sort({_id: 1}).forEach(printjson);

students.updateOne({_id: "S102"}, {$set: {hobby: "Chess"}});
print("\nAfter updating Aryan David's hobby:");
printjson(students.findOne({_id: "S102"}));

students.deleteOne({_id: "S103"});
print("\nAfter deleting S103:");
students.find({labRun: "crud-demo"}).sort({_id: 1}).forEach(printjson);

print(`\nFinal count: ${students.countDocuments({labRun: "crud-demo"})}`);
