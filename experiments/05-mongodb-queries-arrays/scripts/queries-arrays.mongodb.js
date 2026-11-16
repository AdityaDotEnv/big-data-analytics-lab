const dbName = process.env.LAB_DB_NAME || "bcs714d_lab_queries";
const lab = db.getSiblingDB(dbName);
const students = lab.students;
const food = lab.food;

students.deleteMany({labRun: "query-demo"});
students.insertMany([
  {_id: 1, name: "Simon", grade: "VII", hobby: "Surfing", labRun: "query-demo"},
  {_id: 2, name: "Aryan David", grade: "VII", hobby: "Chess", location: null, labRun: "query-demo"},
  {_id: 3, name: "Hersch Gibbs", grade: "VIII", hobby: "Graffiti", location: null, labRun: "query-demo"},
  {_id: 4, name: "Maya", grade: "VII", hobby: "Skating", labRun: "query-demo"},
  {_id: 5, name: "Paul Adams", grade: "IX", hobby: "Chess", labRun: "query-demo"}
]);

print("\nNULL or missing Location:");
students.find({location: null}, {_id: 1, name: 1, location: 1}).forEach(printjson);
print("\nCount all and Grade VII:");
print(`all=${students.countDocuments({labRun:"query-demo"})}, gradeVII=${students.countDocuments({grade:"VII", labRun:"query-demo"})}`);
print("\nFirst 3 Grade VII students:");
students.find({grade:"VII", labRun:"query-demo"}).limit(3).forEach(printjson);
print("\nNames ascending:");
students.find({labRun:"query-demo"}, {_id:0, name:1}).sort({name:1}).forEach(printjson);
print("\nSkip first 2:");
students.find({labRun:"query-demo"}).sort({_id:1}).skip(2).forEach(printjson);
print("\nHobby in Chess or Skating:");
students.find({hobby: {$in:["Chess","Skating"]}, labRun:"query-demo"}).forEach(printjson);
print("\nName begins with M:");
students.find({name: /^M/, labRun:"query-demo"}).forEach(printjson);

food.deleteMany({labRun: "array-demo"});
food.insertMany([
  {_id: 1, fruits: ["banana","apple","cherry"], labRun:"array-demo"},
  {_id: 2, fruits: ["orange","butterfruit","mango"], labRun:"array-demo"},
  {_id: 3, fruits: ["pineapple","strawberry","grapes"], labRun:"array-demo"},
  {_id: 4, fruits: ["banana","strawberry","grapes"], labRun:"array-demo"},
  {_id: 5, fruits: ["orange","grapes"], labRun:"array-demo"}
]);
print("\nFood documents with banana:");
food.find({fruits:"banana", labRun:"array-demo"}).forEach(printjson);
print("\nArrays of length 2:");
food.find({fruits: {$size:2}, labRun:"array-demo"}).forEach(printjson);
print("\nArrays containing both orange and grapes:");
food.find({fruits: {$all:["orange","grapes"]}, labRun:"array-demo"}).forEach(printjson);
print("\nFirst two fruits of document 1:");
printjson(food.findOne({_id:1, labRun:"array-demo"}, {fruits: {$slice:2}}));
print("\nUpdate document 4 array index 1:");
food.updateOne({_id:4, labRun:"array-demo"}, {$set: {"fruits.1":"apple"}});
printjson(food.findOne({_id:4, labRun:"array-demo"}));
print("\nAdd orange uniquely to document 4:");
food.updateOne({_id:4, labRun:"array-demo"}, {$addToSet:{fruits:"orange"}});
printjson(food.findOne({_id:4, labRun:"array-demo"}));
