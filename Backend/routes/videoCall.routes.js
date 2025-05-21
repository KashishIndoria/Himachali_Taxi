const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const videoCallController = require('../controllers/videoCall.controller');

// Video Call Routes
router.post('/initiate', auth, videoCallController.initiateCall);
router.post('/end', auth, videoCallController.endCall);
router.get('/history', auth, videoCallController.getCallHistory);
router.get('/current', auth, videoCallController.getCurrentCall);

module.exports = router; 