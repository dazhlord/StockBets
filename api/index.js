const express = require("express");
const app = express();
const bodyParser = require("body-parser");
app.use(bodyParser.json());

const port = 3000;

// POST: Run any SQL Statement
// BODY: { "statement": "SELECT * FROM table" }

app.post("/sendStatement", async function (req, res) {
  const { sendStatement } = require("./src/snowflake");
  console.log(req.body);
  const { statement } = req.body;
  if (!statement) return res.status(400).send("Statement is required");
  const cases = await sendStatement(statement);
  res.status(200).send(cases);
});

// Start Server
// app.listen(port, function () {
//   console.log("listening on http://localhost:" + port);
// });

module.exports = app;
