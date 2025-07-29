// Do we need This in future?

// import 'package:hive_flutter/hive_flutter.dart';

// class GuestDataBase {
//   List guestList = [];

//   // reference our box
//   final _myBoxGuest = Hive.box('myboxGuest');

//   // run this method if this is the 1st time ever opening this app
//   List createInitialDataGuest() {
//     guestList = [
//       ["Gast 1", false, false, false],
//       ["Gast 2", false, false, false],
//     ];
//     return guestList;
//   }

//   // load the data from database Guests
//   void loadDataGuest() {
//     guestList = _myBoxGuest.get("GUESTLIST");
//   }

//   // update the database Guests
//   void updateDataBaseGuest() {
//     _myBoxGuest.put("GUESTLIST", guestList);
//   }
// }
