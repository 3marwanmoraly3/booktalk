import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenLibraryService {
  Future<List<Book>> bookSearch(String query) async {
    final response = await http.get(
      Uri.parse('https://openlibrary.org/search.json?q=$query'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List books = data['docs'];
      return books.map((book) => Book.fromJson(book)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<String> getBookISBN(String bookTitle) async {
    String url =
        'https://openlibrary.org/search.json?q=${Uri.encodeQueryComponent(bookTitle)}';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['docs'] != null && data['docs'].isNotEmpty) {
        if (data['docs'][0]['isbn'] != null &&
            data['docs'][0]['isbn'].isNotEmpty) {
          return data['docs'][0]['isbn'][0];
        }
      }
    }
    return "Book ISBN not found";
  }

  Future<String> fetchPublishDate(String isbn) async {
    final url =
        'https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final RequestedBook = data['ISBN:$isbn'];

      if (RequestedBook != null) {
        final publishDate = RequestedBook['publish_date'];
        return publishDate;
      } else {
        return 'book publish date not found for ISBN $isbn';
      }
    } else {
      throw Exception('Failed to load book details');
    }
  }

  Future<String> fetchBookCover(String isbn) async {
    final url = 'https://covers.openlibrary.org/b/isbn/${isbn}-M.jpg';
    final response = await http.get(Uri.parse(url));
    try {
      if (response.statusCode == 200) {
        return url;
      } else {
        return "";
      }
    } catch (e) {
      print('Error Fetching book cover:$e');
      return "";
    }
  }
}

class Book {
  final String title;
  final String author;
  final String description;
  final String isbn;
  final String? coverUrl;

  Book(
      {required this.title,
        required this.author,
        this.coverUrl,
        this.description = 'No description available',
        this.isbn = "no isbn found for this book"});

  factory Book.fromJson(Map<String, dynamic> json) {
    final coverUrl = json['cover_i'] != null
        ? 'http://covers.openlibrary.org/b/id/${json['cover_i']}-M.jpg'
        : null;

    return Book(
      title: json['title'] ?? 'No title',
      author: (json['author_name'] ?? ['Unknown Author']).join(', '),
      description:
      json['first_sentence'] != null && json['first_sentence'] is List
          ? (json['first_sentence'] as List).join(' ')
          : 'No description available',
      coverUrl: coverUrl,
    );
  }
}