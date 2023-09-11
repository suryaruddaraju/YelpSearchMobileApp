import express from "express";
import cors from "cors";
// import { samp_rest } from "./data.ts";
import http from 'http';

'use strict';

import yelp from 'yelp-fusion';
const client = yelp.client('-il3C97CTaabTmPM4RcOcbJIDGseAnC4wEupXvvSYj8RIAPUPVPK05HC9pl1fu4v3aMWkIlu2-rZSf9B_OnOC2d0-MyjS_cpgZUYuh6X8Cuco5G8drsyxMIwCTg-Y3Yx');

const app = express();
app.use(cors({
    credentials:true,
    origin:["https://angular-appfe.wn.r.appspot.com/search"]
}));

// Add Access Control Allow Origin headers
app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );
  next();
});

// app.get("/api/restaurants", (req, res) => {
//     res.send(samp_rest);
// });

// app.get("/api/location/:loc", (req, res) => {

//   var path = encodeURI("/maps/api/geocode/json?address="+ req.params.loc +"&key=AIzaSyClGHeQVPCpVDhOZUhhwx3YzM955N6GlsI");
//   const options = {
//     hostname: 'https://maps.googleapis.com',
//     path: path,
//     method: 'GET',
//     headers: {
//       'Content-Type': 'application/json',
//     },
//   };
  
//   console.log("in get loc")
//   // console.log("url");
//   // res.send(url);  
//   let data = "";
//   const request = http.request(options, (response) => {
//     // Set the encoding, so we don't get log to the console a bunch of gibberish binary data
//     response.setEncoding('utf8');

//     // As data starts streaming in, add each chunk to "data"
//     response.on('data', (chunk) => {
//       data += chunk;
//     });

//     // The whole response has been received. Print out the result.
//     response.on('end', () => {
//       console.log(data);
//     });
//   });

  // Log errors if any occur
  request.on('error', (error) => {
    console.error(error);
  });

  // End the request
  request.end();
});

app.get("/api/restaurants/search/:keywd/:lat/:long/:category/:radius", (req, res) => {
    client.search({
        term: req.params.keywd,
        latitude: req.params.lat,
        longitude: req.params.long,
        categories:req.params.category,
        radius: req.params.radius,
        limit: 20
      }).then(response => {
        // console.log(res.jsonBody.businesses[0].name);
        res.send(response.jsonBody)
      }).catch(e => {
        console.log(e);
      });
});

app.get('/api/getRestaurants/:name', (req, res) => {
  client.business(req.params.name).then(response => {
    console.log("PHOTOS ON SERVER: " + response.jsonBody.photos);
    res.send(response.jsonBody)
  }).catch(e => {
    console.log("THIS IS THE ERROR**************************************************************************************************************************" + e);
  });
})

app.get('/api/reviews/:name', function (req, res) {
  // res.send(samp_rest)
  client.reviews(req.params.name).then(response => {
    // console.log(response.jsonBody.reviews);
    res.send(response.jsonBody)
  }).catch(e => {
    console.log("THIS IS THE ERROR**************************************************************************************************************************" + e);
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
    console.log("website served on http://localhost:" + port);
});