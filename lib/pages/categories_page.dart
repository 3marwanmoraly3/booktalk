import 'package:flutter/material.dart';
import 'genre_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffDCE9FF),
      body: Padding(
        padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            GenreButton(
                genre: 'Fiction',
                onPressed: () => navigateToGenrePage(context, 'Fiction')),
            GenreButton(
                genre: 'Romance',
                onPressed: () => navigateToGenrePage(context, 'Romance')),
            GenreButton(
                genre: 'Mystery',
                onPressed: () => navigateToGenrePage(context, 'Mystery')),
            GenreButton(
                genre: 'Thriller',
                onPressed: () => navigateToGenrePage(context, 'Thriller')),
            GenreButton(
                genre: 'Science Fiction',
                onPressed: () =>
                    navigateToGenrePage(context, 'Science Fiction')),
            GenreButton(
                genre: 'Fantasy',
                onPressed: () => navigateToGenrePage(context, 'Fantasy')),
            GenreButton(
                genre: 'Biography',
                onPressed: () => navigateToGenrePage(context, 'Biography')),
            GenreButton(
                genre: 'History',
                onPressed: () => navigateToGenrePage(context, 'History')),
            GenreButton(
                genre: 'Self-Help',
                onPressed: () => navigateToGenrePage(context, 'Self-Help')),
            GenreButton(
                genre: 'Poetry',
                onPressed: () => navigateToGenrePage(context, 'Poetry')),
            GenreButton(
                genre: 'Business',
                onPressed: () => navigateToGenrePage(context, 'Business')),
            GenreButton(
                genre: 'Travel',
                onPressed: () => navigateToGenrePage(context, 'Travel')),
          ],
        ),
      ),
    );
  }

  void navigateToGenrePage(BuildContext context, String genre) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GenrePage(genre: genre)),
    );
  }
}

class GenreButton extends StatelessWidget {
  final String genre;
  final VoidCallback onPressed;

  const GenreButton({super.key, required this.genre, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          genre,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Color(0xff6255FA),
        ),
      ),
    );
  }
}
