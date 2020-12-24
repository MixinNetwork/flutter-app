import 'dart:math';

// Todo remove
List<String> avatars = [
  'https://i1.hdslb.com/bfs/face/737dbfa8072f5d57046f58efcb9bbb3a4e680266.png',
  'https://i1.hdslb.com/bfs/face/3e285abab2a9fd1d52fb640a03f7d458bf139045.jpg',
  'https://i1.hdslb.com/bfs/face/bc5ca101313d4db223c395d64779e76eb3482d60.jpg',
  'https://i2.hdslb.com/bfs/face/48ad92f9e0eb9516f491ed18457e2a73e865ea8c.jpg',
  'https://i2.hdslb.com/bfs/face/022ed8d37575bebe32346ba210395f9fe98a6a10.jpg',
  'https://i1.hdslb.com/bfs/face/1d6f100b921c9b48914eda8f3b37e76ba9ef4ca5.jpg',
  'https://i0.hdslb.com/bfs/face/16d4089d378a421d33bb56f7067727be0a992d7c.jpg',
  'https://i1.hdslb.com/bfs/face/836a17376b6d1c21200310137256c91731045d1b.jpg',
  'https://i2.hdslb.com/bfs/face/2bb27602ede08bc063630711678da524928f5957.jpg',
  'https://i2.hdslb.com/bfs/face/1b1fbd26ca19e309425ba58c46822b04a20bdf17.jpg',
  'https://i1.hdslb.com/bfs/face/812153babfd30220e578529226017267a8c0cb48.jpg',
  'https://i0.hdslb.com/bfs/face/d22eb3b15757459151f03543e479e4290b903489.jpg',
  'https://i2.hdslb.com/bfs/face/63ec36b6be3f3b21169766d92cf372966c9377d5.jpg',
  'https://i1.hdslb.com/bfs/face/a34eddc74f7bffb96f77b37b4f27b793d892863b.jpg',
  'https://i0.hdslb.com/bfs/face/cf5d77195b1e2aa8a3bd3e05b01f20e6ec88d044.jpg',
  'https://i2.hdslb.com/bfs/face/c42c4bfd2f2621442b700d5655e252e1705a7438.jpg',
  'https://i0.hdslb.com/bfs/face/c63ebeed7d49967e2348ef953b539f8de90c5140.jpg',
  'https://i2.hdslb.com/bfs/face/cf73990d6589ee4374470ce3c8daa9200ee2509e.jpg',
  'https://i2.hdslb.com/bfs/face/8f80f1a4e71d2be308f578dcb2a2e1c70a8c3927.jpg',
  'https://i2.hdslb.com/bfs/face/e7c191e9be6764107415069b36f7d9564f149c86.gif',
  'https://i2.hdslb.com/bfs/face/068939602dae190c86f6b36ca301281d7d8aa6d9.jpg',
  'https://i1.hdslb.com/bfs/face/8c9c6777325ad761d7b120840bbc36eb7bbcaf92.jpg',
  'https://i0.hdslb.com/bfs/face/1871c834255ffea531f699164e70f0daebc7558b.jpg',
  'https://i1.hdslb.com/bfs/face/1ed489ddefe1a1fd1dd012dbf17f277d1df39ab9.jpg',
  'https://i0.hdslb.com/bfs/face/825144ab9916b97a92cbda588345964b0b1fca34.jpg',
  'https://i2.hdslb.com/bfs/face/e29079968cc3670f39c43ecc57d09bedb61aae25.jpg',
  'https://i1.hdslb.com/bfs/face/ba076b3acd37c2276ea3f43c8ffd5c1ba46c1d6a.jpg',
  'https://i0.hdslb.com/bfs/face/de4ebdba67164cc8d42d32723efbd91f53b6cb58.jpg@'
];
// Mock avatar
List<String> moackAvatar(int index) {
  return getRandomElement(Random().nextInt(4) + 1);
}

List<String> getRandomElement<T>(int count) {
  final result = <String>[];
  var j = -1;
  var x = -1;

  for (var i = 0; i < count; i++) {
    do {
      x = Random().nextInt(avatars.length);
    } while (x == j);
    j = x;
    x = -1;
    result.add(avatars[j]);
  }
  return result;
}
