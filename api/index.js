const express = require("express");
const app = express();
const bodyParser = require("body-parser");
app.use(bodyParser.json());

const port = 3000;

// GET: Get Covid19 cases in California
app.get("/getCases", async function (req, res) {
  const { getCases } = require("./src/snowflake");
  const cases = await getCases();
  res.status(200).send(cases);
});

// POST: Run any SQL Statement
// BODY: { "statement": "SELECT * FROM table" }

app.post("/getCases", async function (req, res) {
  const { getCases } = require("./src/snowflake");
  console.log(req.body);
  const { statement } = req.body;
  if (!statement) return res.status(400).send("Statement is required");
  const cases = await getCases(statement);
  res.status(200).send(cases);
});

// GET: Get test response with all types of data
app.get("/test", async function (req, res) {
  // create an object with all data types and exampel values
  const test = {
    string: "string",
    number: 1,
    boolean: true,
    array: [1, 2, 3],
    object: {
      key: "value",
    },
  };
  res.status(200).send(test);
});

// Start Server
app.listen(port, function () {
  console.log("listening on http://localhost:" + port);
});

// module.exports = app;
