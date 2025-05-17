const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/user/signup', authController.userSignup);
router.post('/verify-otp', authController.verifyOTP);
router.post('/user/login', authController.userLogin);
router.post('/captain/signup', authController.captainSignup);
router.post('/captain/login', authController.captainLogin);
router.post('/resend-otp', authController.resendOTP);

module.exports = router;