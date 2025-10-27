import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collections
  CollectionReference get _conversationsCollection =>
      _firestore.collection('chat_conversations');
  CollectionReference get _messagesCollection =>
      _firestore.collection('chat_messages');

  // Get or create conversation between patient and doctor
  Future<String> getOrCreateConversation({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
  }) async {
    try {
      // Check if conversation already exists
      QuerySnapshot existingConversation = await _conversationsCollection
          .where('patientId', isEqualTo: patientId)
          .where('doctorId', isEqualTo: doctorId)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Create new conversation
      DocumentReference conversationRef = await _conversationsCollection.add({
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'lastMessage': 'Conversation started',
        'lastMessageTime': Timestamp.now(),
        'lastMessageSenderId': '',
        'unreadCount': 0,
        'isActive': true,
        'createdAt': Timestamp.now(),
      });

      return conversationRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: ${e.toString()}');
    }
  }

  // Get conversations for a user
  Stream<List<ChatConversationModel>> getUserConversations(String userId) {
    return _conversationsCollection
        .where('isActive', isEqualTo: true)
        .where(Filter.or(
          Filter('patientId', isEqualTo: userId),
          Filter('doctorId', isEqualTo: userId),
        ))
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatConversationModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Get messages for a conversation
  Stream<List<ChatMessageModel>> getConversationMessages(String conversationId) {
    return _messagesCollection
        .where('chatId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to last 50 messages for performance
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  // Send text message
  Future<void> sendTextMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
  }) async {
    try {
      final message = ChatMessageModel(
        id: '',
        chatId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      await _messagesCollection.add(message.toMap());
      await _updateConversationLastMessage(conversationId, content, senderId);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Upload file to Firebase Storage
  Future<String> uploadFile(File file, String fileName) async {
    try {
      String filePath = 'chat_files/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference ref = _storage.ref().child(filePath);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  // Send image message
  Future<void> sendImageMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required File imageFile,
    String? caption,
  }) async {
    try {
      String fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String imageUrl = await uploadFile(imageFile, fileName);

      final message = ChatMessageModel(
        id: '',
        chatId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: caption ?? 'Image',
        type: MessageType.image,
        fileUrl: imageUrl,
        fileName: fileName,
        fileSize: await imageFile.length(),
        timestamp: DateTime.now(),
      );

      await _messagesCollection.add(message.toMap());
      await _updateConversationLastMessage(conversationId, '📷 Image', senderId);
    } catch (e) {
      throw Exception('Failed to send image: ${e.toString()}');
    }
  }

  // Send file message
  Future<void> sendFileMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required File file,
    required String fileName,
  }) async {
    try {
      String fileUrl = await uploadFile(file, fileName);

      final message = ChatMessageModel(
        id: '',
        chatId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: 'File: $fileName',
        type: MessageType.file,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: await file.length(),
        timestamp: DateTime.now(),
      );

      await _messagesCollection.add(message.toMap());
      await _updateConversationLastMessage(conversationId, '📎 $fileName', senderId);
    } catch (e) {
      throw Exception('Failed to send file: ${e.toString()}');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      QuerySnapshot unreadMessages = await _messagesCollection
          .where('chatId', isEqualTo: conversationId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (QueryDocumentSnapshot doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count in conversation
      await _conversationsCollection.doc(conversationId).update({
        'unreadCount': 0,
      });
    } catch (e) {
      throw Exception('Failed to mark messages as read: ${e.toString()}');
    }
  }

  // Update conversation last message
  Future<void> _updateConversationLastMessage(
    String conversationId,
    String lastMessage,
    String senderId,
  ) async {
    try {
      DocumentSnapshot conversationDoc =
          await _conversationsCollection.doc(conversationId).get();
      
      if (conversationDoc.exists) {
        Map<String, dynamic> data = conversationDoc.data() as Map<String, dynamic>;
        int currentUnreadCount = data['unreadCount'] ?? 0;
        
        await _conversationsCollection.doc(conversationId).update({
          'lastMessage': lastMessage,
          'lastMessageTime': Timestamp.now(),
          'lastMessageSenderId': senderId,
          'unreadCount': currentUnreadCount + 1,
        });
      }
    } catch (e) {
      throw Exception('Failed to update conversation: ${e.toString()}');
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _conversationsCollection.doc(conversationId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception('Failed to delete conversation: ${e.toString()}');
    }
  }

  // Get conversation by ID
  Future<ChatConversationModel?> getConversationById(String conversationId) async {
    try {
      DocumentSnapshot doc = await _conversationsCollection.doc(conversationId).get();
      if (doc.exists) {
        return ChatConversationModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get conversation: ${e.toString()}');
    }
  }
}