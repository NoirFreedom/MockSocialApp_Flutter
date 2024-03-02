import 'dart:io';

import 'package:TikTok/features/videos/models/video_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a video file
  UploadTask uploadVideoFile(File video, String uid) {
    final fileRef = _storage.ref().child(
        "/videos/$uid/${DateTime.now().millisecondsSinceEpoch.toString()}");
    return fileRef.putFile(video);
  }

  Future<void> saveVideo(VideoModel data) async {
    await _db.collection("videos").add(data.toJson());
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchVideos(
      {int? lastItemCreatedAt}) {
    final query = _db
        .collection("videos")
        .orderBy("createdAt", descending: true)
        .limit(2);

    if (lastItemCreatedAt == null) {
      return query.get();
    } else {
      return query.startAfter([lastItemCreatedAt]).get();
    }
  }

  Future<void> toggleLikeVideo(String videoId, String userId) async {
    final query = _db.collection("likes").doc("${videoId}000$userId");

    final like = await query.get();

    if (!like.exists) {
      await query.set({
        "createdAt": DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await query.delete();
    }
  }

  Future<bool> isLikedVideo(String videoId, String userId) async {
    final query =
        _db.collection("users").doc(userId).collection("likes").doc(videoId);
    final documentSnapshot = await query.get();
    return documentSnapshot.exists;
  }

  Future<int> fetchLikesCount(String videoId) async {
    final videoDoc = await _db.collection('videos').doc(videoId).get();
    if (videoDoc.exists && videoDoc.data()!.containsKey('likes')) {
      return videoDoc.data()!['likes'] as int;
    } else {
      return 0; // 문서가 없거나 'likes' 필드가 없는 경우 0 반환
    }
  }
}

final videoRepo = Provider((ref) => VideoRepository());
