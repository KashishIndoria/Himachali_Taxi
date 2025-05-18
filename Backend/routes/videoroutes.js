const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { 
    initiateVideoCall,
    endVideoCall,
    uploadSafetyVideo,
    getSafetyVideos,
    uploadTrainingVideo,
    getTrainingVideos,
    getVideoCallHistory
} = require('../controllers/videoController');
const upload = require('../middleware/upload');

// Video Call Routes
router.post('/call/initiate', auth, initiateVideoCall);
router.post('/call/end', auth, endVideoCall);
router.get('/call/history', auth, getVideoCallHistory);

// Safety Video Routes
router.post('/safety/upload', auth, upload.single('video'), uploadSafetyVideo);
router.get('/safety', auth, getSafetyVideos);

// Training Video Routes
router.post('/training/upload', auth, upload.single('video'), uploadTrainingVideo);
router.get('/training', auth, getTrainingVideos);

module.exports = router; 