class SetlistPresentationScreen extends StatefulWidget {
  final Setlist setlist;
  
  const SetlistPresentationScreen({Key? key, required this.setlist}) : super(key: key);
  
  @override
  _SetlistPresentationScreenState createState() => _SetlistPresentationScreenState();
}

class _SetlistPresentationScreenState extends State<SetlistPresentationScreen> {
  late Setlist _setlist;
  
  @override
  void initState() {
    super.initState();
    _setlist = widget.setlist;
    _setlist.addListener(_onSetlistChanged);
  }
  
  void _onSetlistChanged() {
    setState(() {});
  }
  
  void _nextSong() {
    _setlist.nextSong();
  }
  
  void _previousSong() {
    _setlist.previousSong();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentSetlistSong = _setlist.currentSong;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_setlist.name),
        actions: [
          // Contador de canciones
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_setlist.songs.indexOf(currentSetlistSong!) + 1}/${_setlist.songs.length}',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: currentSetlistSong == null 
          ? Center(child: Text('No hay canciones en el setlist'))
          : FutureBuilder<Song?>(
              future: SongRepository().getSongById(currentSetlistSong.songId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Error al cargar canción'));
                }
                
                return PresentationScreen(
                  song: snapshot.data!,
                  onNext: _setlist.hasNext ? _nextSong : null,
                  onPrevious: _setlist.hasPrevious ? _previousSong : null,
                );
              },
            ),
      // Botones de navegación flotantes
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_setlist.hasPrevious)
            FloatingActionButton(
              heroTag: 'prev',
              onPressed: _previousSong,
              child: Icon(Icons.skip_previous),
              mini: true,
            ),
          SizedBox(height: 10),
          if (_setlist.hasNext)
            FloatingActionButton(
              heroTag: 'next',
              onPressed: _nextSong,
              child: Icon(Icons.skip_next),
              mini: true,
            ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _setlist.removeListener(_onSetlistChanged);
    super.dispose();
  }
}