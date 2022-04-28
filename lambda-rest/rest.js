const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();




let statusCode = 200;
let body = {};



module.exports.handler = async (event, context) => {


  const headers = {
    "Content-Type": "application/json"
  };
  console.log('Event: ', event);
  console.log("Route Key", event.httpMethod);
  try {
    switch (event.httpMethod) {
      case "GET":
        body = await dynamo.scan({ TableName: "http-crud-tutorial-items" }).promise();
        break;
      case "POST":
        let requestJSON = JSON.parse(event.body);
        await dynamo.put({
          TableName: "items-table",
          Item: {
            id: 0,
            price: "34.4",
            name: "name"
          }
        })
          .promise();
        body = `Put item ${requestJSON.id}`;
        break;


      case "PUT":
        break;
      case "DELETE":
        break;

    }
  }
  catch (err) {
    statusCode = 400,
      body = err.message
  } finally {
    body = JSON.stringify(body)
  }
  return {
    statusCode,
    body,
    headers
  }


}
