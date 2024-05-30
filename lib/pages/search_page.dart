import 'book_page.dart';
import 'package:flutter/material.dart';
import 'package:booktalk/books_library_api.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _bookNameController = TextEditingController();
  List<Book> _resultBooks = [];
  bool _isLoading = false;
  OpenLibraryService ols = OpenLibraryService();

  Future<void> _searchBooks(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ols.bookSearch(query);
      setState(() {
        _resultBooks = results;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFdce9ff),
      body: Padding(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(children: [
          TextField(
            controller: _bookNameController,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search',
              hintStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 24),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
              suffixIcon: Icon(Icons.search_rounded, size: 30),
            ),
            onSubmitted: (query) {
              query = _bookNameController.text;
              _searchBooks(query);
            },
          ),
          SizedBox(height: 20.0),
          if (_isLoading)
            CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _resultBooks.length,
                itemBuilder: (context, index) {
                  final book = _resultBooks[index];
                  return ListTile(
                    title: Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(book.author),
                    onTap: () async {
                      _showLoadingDialog(context);
                      await _navigateToBookPage(book);
                      Navigator.pop(context); // Dismiss the loading dialog
                    },
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }

  Future<void> _navigateToBookPage(Book book) async {
    final isbn = await ols.getBookISBN(book.title);
    final date = await ols.fetchPublishDate(isbn);
    final imageUrl = await ols.fetchBookCover(isbn);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookPage(
          selectedBook: book,
          selectedBookISBN: isbn,
          publishDate: date,
          imageurl: imageUrl,
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
