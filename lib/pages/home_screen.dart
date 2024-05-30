import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<QueryDocumentSnapshot> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('Review')
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

    final userDoc = await FirebaseFirestore.instance.collection('User').doc(userID).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future<String> fetchBookTitle(String isbn) async {
    final response = await http.get(Uri.parse('https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data'));
    if (response.statusCode == 200) {
      final bookData = json.decode(response.body);
      return bookData['ISBN:$isbn']?['title'] ?? 'Unknown Title';
    } else {
      return 'Unknown Title';
    }
  }

  Widget getCoverImage(String? bookISBN) {
    if (bookISBN == null) {
      return Image(
        image: AssetImage('assets/images/default_book_cover.jpg'),
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      'http://covers.openlibrary.org/b/isbn/$bookISBN-M.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image(
          image: AssetImage('assets/images/default_book_cover.jpg'),
          fit: BoxFit.cover,
        );
      },
    );
  }

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

  String formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy – hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffDCE9FF),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          final reviewData = review.data() as Map<String, dynamic>?;
          final userID = reviewData?['UserID'] as String?;
          final bookISBN = reviewData?['BookISBN'] as String?;

          return FutureBuilder<Map<String, dynamic>?>(
            future: getUserData(userID),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading user data'));
              }

              final userData = snapshot.data;
              final userName = userData?['Username'] ?? 'Unknown User';
              final avatarUrl = userData?['AvatarUrl'];

              return Padding(
                padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.0),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 95,
                              height: 135,
                              child: getCoverImage(bookISBN),
                            ),
                            FutureBuilder<String>(
                              future: fetchBookTitle(bookISBN ?? ''),
                              builder: (context, bookSnapshot) {
                                if (bookSnapshot.hasError) {
                                  return const Text(
                                    'Error',
                                    style: TextStyle(fontSize: 12, color: Colors.red),
                                    textAlign: TextAlign.center,
                                  );
                                }
                                return SizedBox(
                                  width: 95,
                                  child: Text(
                                    bookSnapshot.data ?? 'Unknown Title',
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 3,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  getUserAvatar(avatarUrl),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '${reviewData?['ReviewScore'] ?? 0} / 5',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              SizedBox(
                                height: 80.0,
                                child: Text(
                                  reviewData?['Review'] ?? 'No review available',
                                  style: const TextStyle(fontSize: 14.0),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                reviewData?['Timestamp'] == null
                                    ? 'No timestamp available'
                                    : formatTimestamp(reviewData?['Timestamp'] as Timestamp),
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
