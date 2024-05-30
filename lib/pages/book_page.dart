import 'dart:async';
import 'package:booktalk/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:booktalk/books_library_api.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/services.dart';

class BookPage extends StatefulWidget {
  final Book selectedBook;
  final String selectedBookISBN;
  final String publishDate;
  final String imageurl;

  BookPage(
      {required this.selectedBook,
      this.selectedBookISBN = 'no isbn found',
      this.publishDate = 'no date found',
      required this.imageurl});
  _BookPage createState() => _BookPage();
}

class _BookPage extends State<BookPage> {
  _BookPage();
  List<QueryDocumentSnapshot> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('Review')
        .where('BookISBN', isEqualTo: widget.selectedBookISBN)
        .orderBy('Timestamp', descending: true)
        .get();
    setState(() {
      reviews = reviewsSnapshot.docs;
    });
  }

  Future<Map<String, dynamic>?> getUserData(String? userID) async {
    if (userID == null) {
      return null;
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('User').doc(userID).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  bool isNumeric(String str) {
    if(str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  Future<void> ReviewSetup(String rev, int revScore) async {
    CollectionReference reviews =
        FirebaseFirestore.instance.collection('Review');
    String review = rev;
    int reviewScore = revScore;
    String ISBN = widget.selectedBookISBN;
    String? userid =
        await getUserId(); // Await the Future and get the String? value
    if (userid != null) {
      // Check if userid is not null before using it
      Timestamp timestamp = Timestamp.now();
      reviews.add({
        'Review': review,
        'ReviewScore': reviewScore,
        'BookISBN': ISBN,
        'UserID': userid,
        'Timestamp': timestamp
      });
    } else {
      // Handle the case where userid is null
      print('Error: User ID is null');
    }
  }

  Widget getCoverImage(String imageUrl) {
    if (imageUrl == "") {
      return Image(
        width: 150,
        height: 225,
        image: AssetImage('assets/images/default_book_cover.jpg'),
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      imageUrl,
      width: 150,
      height: 225,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image(
          image: AssetImage('assets/images/default_book_cover.jpg'),
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xffDCE9FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'BookTalk',
            style: TextStyle(
                fontSize: 24,
                color: Color(0xff6255FA),
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFFdce9ff),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Color(0xff6255FA),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Color(0xFFdce9ff),
        body: Padding(
          padding: EdgeInsets.only(right: 20, top: 10, left: 20),
          child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: getCoverImage(widget.imageurl)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.selectedBook.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 4,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          '${widget.selectedBook.author}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                        SizedBox(height: 8.0),
                        Text('ISBN: ${widget.selectedBookISBN}',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black)),
                        SizedBox(height: 8.0),
                        Text(
                          'Pub. Date: ${widget.publishDate}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              Text(
                "Synopsis",
                style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.0),
              ExpandableText(
                "${widget.selectedBook.description}",
                expandText: 'More',
                collapseText: 'Less',
                maxLines: 4,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10.0),
              Text(
                "Reviews",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10.0),
              SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _writeReview,
                  child: const Text(
                    'Write your own review',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Color(0xff6255FA),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('Review')
                    .where('BookISBN', isEqualTo: widget.selectedBookISBN)
                    .snapshots(),
                builder: (context, Usersnapshot) {
                  if (!Usersnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Container(
                    padding: const EdgeInsets.all(10),
                    height: 400,
                    child: ListView.builder(
                      itemCount: Usersnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot ds =
                            Usersnapshot.data!.docs[index];
                        final reviewData = ds.data() as Map<String, dynamic>?;
                        final userID = reviewData?['UserID'] as String?;

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: getUserData(userID),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Error loading user data'));
                            }

                            final userData = snapshot.data;
                            final userName =
                                userData?['Username'] ?? 'Unknown User';
                            final avatarUrl = userData?['AvatarUrl'] ?? '';

                            return UserReviews(
                              review: reviewData?['Review'],
                              reviewScore: reviewData?['ReviewScore'],
                              timeStamp: reviewData?['Timestamp'],
                              username: userName,
                              avatarUrl: avatarUrl,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              )
            ]),
          ),
        ),
      ),
    );
  }

  void _writeReview() {
    showDialog(
        context: context,
        builder: (BuildContext) {
          TextEditingController _reviewInput = TextEditingController();
          TextEditingController _ratingInput = TextEditingController();

          return AlertDialog(
            backgroundColor: Color(0xff6255FA),
            content: Container(
              height: 400,
              width: 9999,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [TextField(
                        controller: _reviewInput,
                        minLines: 7,
                        maxLines: 7,
                        style: TextStyle(fontSize: 20),
                        decoration: InputDecoration(
                          hintText: 'Write your review here...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide(color: Colors.black, width: 2),
                          ),
                        ),
                      ),
                    SizedBox(height: 10.0),
                    TextField(
                      controller: _ratingInput,
                      style: TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Rating / 5',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    SizedBox(
                      width: 150,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_ratingInput.text.isEmpty ||
                              _reviewInput.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Review cannot be empty')));
                          } else if (!isNumeric(_ratingInput.text) || int.parse(_ratingInput.text) < 0 || int.parse(_ratingInput.text) > 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Rating is between 0 and 5')));
                          } else {
                            ReviewSetup(_reviewInput.text,
                                int.parse(_ratingInput.text));
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ]),
            ),
          );
        });
  }
}

class UserReviews extends StatelessWidget {
  final String review;
  final int reviewScore;
  final Timestamp timeStamp;
  final String username;
  final String avatarUrl;

  UserReviews(
      {required this.review,
      required this.reviewScore,
      required this.timeStamp,
      required this.username,
      required this.avatarUrl});

  Widget getUserAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return CircleAvatar(
        backgroundImage: AssetImage('assets/images/default_avatar.png'),
      );
    }
    return CircleAvatar(
      backgroundImage: NetworkImage(avatarUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(
                children: [
                  getUserAvatar(avatarUrl),
                  const SizedBox(width: 8.0),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMMM dd, yyyy – hh:mm a')
                    .format(timeStamp.toDate()),
                style: TextStyle(color: Colors.black, fontSize: 14),
              )
            ]),
            SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4.0),
                Text(
                  '${reviewScore} / 5',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            ExpandableText(
              review,
              expandText: 'More',
              collapseText: 'Less',
              maxLines: 2,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ));
  }
}
