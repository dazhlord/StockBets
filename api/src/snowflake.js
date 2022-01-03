require("dotenv").config();
const snowflake = require("snowflake-sdk");

const account = "vta12748";
const username = process.env.USERNAME;
const password = process.env.PASSWORD;

let connection = snowflake.createConnection({
  account,
  username,
  password,
  warehouse: "COMPUTE_WH",
  database: "COVID19",
  schema: "public",
  role: "ACCOUNTADMIN",
});

const covidCasesSQLStatement =
  "SELECT SUM(CONFIRMED) FROM JHU_DASHBOARD_COVID_19_GLOBAL WHERE COUNTRY_REGION = 'United States' AND PROVINCE_STATE = 'California';";

async function getCases(statement = covidCasesSQLStatement) {
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
        const [key] = Object.keys(rows[0]);
        const cases = rows[0][key] / 2;
        if (statement === covidCasesSQLStatement) resolve({ cases });
        else resolve({ [key]: cases });
      },
    });
  });
}

module.exports = {
  getCases,
};
