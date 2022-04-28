const AWS = require("aws-sdk");

const dynamo = new AWS.DynamoDB.DocumentClient();
const dynamoTable = process.env.DYNAMO_DB_TABLE;



let statusCode = 200;
let body = {};
let requestJSON;


module.exports.handler = async (event, context) => {


  const headers = {
    "Content-Type": "application/json"
  };
  console.log('Event: ', event);
  console.log("Route Key", event.httpMethod);
  try {
    switch (event.httpMethod) {
      case "GET":
        if (event.pathParameters) {
          body = body = await dynamo
            .get({
              TableName: dynamoTable,
              Key: {
                id: event.pathParameters.id
              }
            })
            .promise();
        } else {
          body = await dynamo.scan({ TableName: dynamoTable }).promise();
        }

        break;
      case "POST":
        requestJSON = JSON.parse(event.body);
        await dynamo
          .put({
            TableName: dynamoTable,
            Item: {
              id: requestJSON.id,
              price: requestJSON.price,
              product_name: requestJSON.name
            }
          })
          .promise();
        body = `Put item ${requestJSON.id}`;
        break;


      case "PUT":
        requestJSON = JSON.parse(event.body)
        await dynamo.update({
          TableName: dynamoTable,
          UpdateExpression: 'SET product_name= :n, price= :p',
          ExpressionAttributeValues: {

            ':n': requestJSON.name,
            ':p': requestJSON.price,
          },
          Key: {
            id: event.pathParameters.id
          }
        }).promise()
        break;
      case "DELETE":
        await dynamo
          .delete({
            TableName: dynamoTable,
            Key: {
              id: event.pathParameters.id
            }
          })
          .promise();
        body = `Deleted item ${event.pathParameters.id}`;
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
