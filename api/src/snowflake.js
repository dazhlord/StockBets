require("dotenv").config();
const snowflake = require("snowflake-sdk");

let connection = snowflake.createConnection({
  account: "vta12748",
  username: process.env.USERNAME,
  password: process.env.PASSWORD,
  warehouse: "COMPUTE_WH",
  database: "COVID19",
  schema: "public",
  role: "ACCOUNTADMIN",
});

async function sendStatement(statement) {
  return new Promise(function (resolve, reject) {
    connection.connect(function (err, conn) {
      if (err) {
        console.error("Unable to connect: " + err.message);
      } else {
        console.log("Successfully connected to Snowflake.");
      }
    });
    connection.execute({
      sqlText: statement,
      complete: function (err, stmt, rows) {
        if (err) {
          console.error(
            "Failed to execute statement due to the following error: " +
              err.message
          );
          return;
        }
        console.log("Successfully executed statement: " + stmt.getSqlText());
        resolve(rows[0]);
      },
    });
  });
}

module.exports = {
  sendStatement,
};
