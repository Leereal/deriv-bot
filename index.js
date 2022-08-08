// Node.js socket server script
const net = require('net');
require('dotenv').config();

const stake = process.env.STAKE
const expiration = process.env.EXPIRATION //In seconds
const app_id = process.env.APP_ID; // Replace with your app_id or leave as 1089 for testing.
// You can get your token here https://app.deriv.com/account/api-token. 
const token = process.env.TOKEN; // Replace with your API token.

console.log(process.env.TOKEN);
// Create a server object
const server = net.createServer((socket) => {
    socket.on('data', (data) => {
        ws.onmessage({ data: data })
    });

    socket.write('SERVER: Hello! This is server speaking.');
    socket.end('SERVER: Closing connection now.');
}).on('error', (err) => {
    console.error(err);
});

// Open server on port 8888
server.listen(8888, () => {
    console.log('opened server on', server.address().port);
});
const WebSocket = require('ws');

// You can register for an app_id here https://api.deriv.com/docs/app-registration/.


const ws = new WebSocket('wss://ws.binaryws.com/websockets/v3?app_id=' + app_id);


ws.onopen = function(evt) {
    ws.send(JSON.stringify({ "authorize": token })) // First send an authorize call.
    ws.send(JSON.stringify({ ticks: 'R_100' }));
};

ws.onmessage = function(msg) {
    var data = JSON.parse(msg.data);
    // console.log('Response: %o', data); // Uncomment this to see full response data. 
    if (data.error !== undefined) {
        console.log(data.error.message);
        ws.close();
    } else if (data.msg_type == 'authorize') {
        console.log("Authorized to buy");
    } else if (data.msg_type == 'buy') { // Our buy request was successful let's print the results. 
        console.log("Contract Id " + data.buy.contract_id + "\n");
        console.log("Details " + data.buy.longcode + "\n");
    } else if (data.msg_type == 'proposal_open_contract') { // Because we subscribed to the buy request we will receive updates on our open contract. 
        var isSold = data.proposal_open_contract.is_sold;
        if (isSold) { // If `isSold` is true it means our contract has finished and we can see if we won or not.
            console.log("Contract " + data.proposal_open_contract.status + "\n");
            console.log("Profit " + data.proposal_open_contract.profit + "\n");
            // ws.close();
        } else { // We can track the status of our contract as updates to the spot price occur. 
            var currentSpot = data.proposal_open_contract.current_spot;
            var entrySpot = 0;
            if (typeof(data.proposal_open_contract.entry_tick) != 'undefined') {
                entrySpot = data.proposal_open_contract.entry_tick;
            }
            console.log("Entry spot " + entrySpot + "\n");
            console.log("Current spot " + currentSpot + "\n");
            console.log("Difference " + (currentSpot - entrySpot) + "\n");
        }
    } else if (data.msg_type == "signal") {
        console.log("Signal received:" + new Date().toLocaleString());
        let symbol_code;
        const symbol = data.symbol;
        if (symbol == "Volatility 10 Index")
            symbol_code = "R_10"
        else if (symbol == "Volatility 25 Index")
            symbol_code = "R_25"
        else if (symbol == "Volatility 50 Index")
            symbol_code = "R_50"
        else if (symbol == "Volatility 75 Index")
            symbol_code = "R_75"
        else if (symbol == "Volatility 100 Index")
            symbol_code = "R_100"
        else if (symbol == "Volatility 10 (1s) Index")
            symbol_code = "1HZ10V"
        else if (symbol == "Volatility 25 (1s) Index")
            symbol_code = "1HZ25V"
        else if (symbol == "Volatility 50 (1s) Index")
            symbol_code = "1HZ50V"
        else if (symbol == "Volatility 75 (1s) Index")
            symbol_code = "1HZ75V"
        else if (symbol == "Volatility 100 (1s) Index")
            symbol_code = "1HZ100V"
            // #Jumps    
        else if (symbol == "Jump 10 Index")
            symbol_code = "JD10"
        else if (symbol == "Jump 25 Index")
            symbol_code = "JD25"
        else if (symbol == "Jump 50 Index")
            symbol_code = "JD50"
        else if (symbol == "Jump 75 Index")
            symbol_code = "JD75"
        else if (symbol == "Jump 100 Index")
            symbol_code = "JD100"
        ws.send(JSON.stringify({ "authorize": token }))
        ws.send(JSON.stringify({
            "buy": 1,
            "subscribe": 1,
            "price": stake,
            "parameters": { "amount": stake, "basis": "stake", "contract_type": data.trade_option === "buy" ? "CALL" : "PUT", "currency": "USD", "duration": expiration, "duration_unit": "s", "symbol": symbol_code }
        }));
        console.log("Signal Placed Successfully:" + new Date().toLocaleString());
    } else if (data.msg_type == "tick") {
        console.log("Connected: R_100 (" + data.tick.ask + ")");
    } else {
        console.log(data);
    }
};