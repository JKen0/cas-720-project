const express = require('express');
const moment = require('moment');
const axios = require('axios');
const cors = require('cors');
const app = express();
const { StatusCodes } = require('http-status-codes');
const port = 3001;
const host = '127.0.0.1';


app.use(cors());


app.get('/test', async (req, res) => {
    res.send('This is a test route to confirm that the request is working');
});

app.get('/weather/fetchRainFallData', async (req, res) => {
    try{
        // fetch query string params from url
        const {lat, lng, startDateUnix, endDateUnix } = req.query;

        // convert dates to human readable dates whic his used in the weather API
        const startDate = moment(startDateUnix, 'X').format('YYYY-MM-DD');
        const endDate = moment(endDateUnix, 'X').format('YYYY-MM-DD');

        // build API url 
        const apiURL = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lng}&daily=rain_sum&timezone=auto&start_date=${startDate}&end_date=${endDate}`

        // make API request and extract data
        const fetchAPIData = await axios.get(apiURL);
        const extractSumRainArray = fetchAPIData.data.daily.rain_sum;

        // calculate the total sum of rainfall of the returned days from the api rainfall array
        let totalRain = 0.0;
        for(const val of extractSumRainArray) {
            totalRain += val;
        };

        // return the result of the total rainfall to the requested user. 
        res.status(StatusCodes.OK).send({ sumRainfall: totalRain });

    } catch(e) {
        res.status(StatusCodes.BAD_REQUEST).send(e);
    }
});


app.listen(port, host, () => {
    
    console.log(`Node application running on port: ${port}!`)
});



/*
    1. Creating a chainlink request on the smart contract
    2. chainlin recieves and fulfills ()


*/