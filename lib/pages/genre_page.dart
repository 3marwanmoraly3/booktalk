import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:booktalk/books_library_api.dart';
import 'book_page.dart';

class GenrePage extends StatefulWidget {
  final String genre;

  const GenrePage({super.key, required this.genre});

  @override
  _GenrePageState createState() => _GenrePageState();
}

class _GenrePageState extends State<GenrePage> {
  List<Book> books = [];
  bool isLoading = false;
  CancelableOperation? _fetchBooksOperation;
  OpenLibraryService ols = OpenLibraryService();

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      isLoading = true;
    });

    final cancelCompleter = CancelableCompleter();
    _fetchBooksOperation = cancelCompleter.operation;

    try {
      final response = await http.get(Uri.parse(
          'http://openlibrary.org/search.json?q=subject:${widget.genre}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookData = data['docs'] as List;
        if (!cancelCompleter.operation.isCanceled) {
          setState(() {
            books = bookData.map((book) => Book.fromJson(book)).toList();
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to fetch books');
      }
    } catch (e) {
      print('Error fetching books: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fetchBooksOperation?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xffDCE9FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.genre,
            style: const TextStyle(
                color: Color(0xff6255FA),
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xffDCE9FF),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xff6255FA),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Color(0xffDCE9FF),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 20, top: 10, right: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 110,
                      child: ElevatedButton(
                        onPressed: () async {
                          _showLoadingDialog(context);
                          await _navigateToBookPage(book);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 55,
                              height: 80,
                              child: book.coverUrl != null
                                  ? Image.network(
                                      book.coverUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/default_book_cover.jpg',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(
                                width:
                                    10),
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth:
                                        200),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      book.author,
                                      style: const TextStyle(
                                          color: Colors.black38),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _navigateToBookPage(Book book) async {
    final isbn = await ols.getBookISBN(book.title);
    final date = await ols.fetchPublishDate(isbn);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookPage(
          selectedBook: book,
          selectedBookISBN: isbn,
          publishDate: date,
          imageurl: book.coverUrl!,
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Loading..."),
              ],
            ),
          ),
        );
      },
    );
  }
}
