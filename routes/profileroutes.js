const express = require('express');
const router = express.Router();
const {
    getUserProfile,
    updateUserProfile,
    updateUserProfileImage,
} = require('../controllers/profileController');

const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);
router.get('/profile', getUserProfile);
router.put('/update-profile', updateUserProfile);
router.put('/update-profile-image', updateUserProfileImage);

module.exports = router;