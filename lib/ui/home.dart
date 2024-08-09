import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:lottie/lottie.dart'; // Add this package for animations

class Home extends StatefulWidget {
  final String qrCode;

  const Home({Key? key, required this.qrCode}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<Home> {
  late Client httpClient;
  late Web3Client ethClient;
  String? trxHash;
  bool isProcessing = true;
  bool isSuccess = false;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client("https://eth-sepolia.g.alchemy.com/v2/k1zXgtcffCMqtipSO8d-1GOCB2DceSTW", httpClient);
    _processQRCode();
  }

  Future<void> _processQRCode() async {
    try {
      trxHash = await sendCoin(widget.qrCode);
      setState(() {
        isProcessing = false;
        isSuccess = true;
      });
      // Wait for 5 seconds and then navigate back to main.dart
      Timer(Duration(seconds: 5), () {
        Navigator.of(context).pushReplacementNamed('/'); // Assuming '/' is your main route
      });
    } catch (e) {
      print("Error processing QR code: $e");
      setState(() {
        isProcessing = false;
        isSuccess = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing payment: $e")),
      );
      // Wait for 5 seconds and then navigate back to main.dart even if there's an error
      Timer(Duration(seconds: 5), () {
        Navigator.of(context).pushReplacementNamed('/');
      });
    }
  }

  Future<String> sendCoin(String amount) async {
    var bigAmount = BigInt.parse(amount);
    var response = await submit("buyCoin", [bigAmount]);
    print("Transaction hash: $response");
    return response;
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    String credHex = "138531cedd31bbc3cbe02b990b5183894697990695f38b8816b9fff7df9f8d8f";
    EthPrivateKey credEth = EthPrivateKey.fromHex(credHex);
    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
      credEth,
      Transaction.callContract(
        contract: contract,
        function: ethFunction,
        parameters: args,
      ),
      chainId: 11155111,
      fetchChainIdFromNetworkId: false,
    );
    return result;
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("abi.json");
    String contractAddress = "0xD02Fa659755A6666eF9A7741D1A8BB4dE142b6fE";
    final contract = DeployedContract(
      ContractAbi.fromJson(abi, "PZCoin"),
      EthereumAddress.fromHex(contractAddress),
    );
    return contract;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing)
              Lottie.asset(
                'assets/processing_animation.json', // Add this animation file
                width: 200,
                height: 200,
              )
            else if (isSuccess)
              Lottie.asset(
                'assets/success_animation.json', // Add this animation file
                width: 200,
                height: 200,
              )
            else
              Icon(Icons.error_outline, size: 100, color: Colors.red),
            SizedBox(height: 20),
            Text(
              isProcessing ? 'Processing Payment...' :
              isSuccess ? 'Payment Successful!' : 'Payment Failed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Amount: \$${widget.qrCode}',
              style: TextStyle(fontSize: 18),
            ),
            if (trxHash != null && isSuccess)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Transaction Hash:\n$trxHash',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Redirecting in 5 seconds...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}