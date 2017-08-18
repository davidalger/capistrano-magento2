## v0.7.0 Dev Checklist

- [ ] Resolve issues failing static-content deploy on 2.2.0-rc deployment (use -f for 2.2 and newer; rely only on exit codes for errors; possibly set MAGE_MODE env var)
- [x] Remove duplicate composer install command (2.1 and newer support deployment using --no-dev); see davidalger/capistrano-magento2#76
- [ ] Verify 2.1.1 and newer deployment ability
- [ ] Verify 2.2-RC2.0 deployment ability
- [x] Verify 2.1.0 and older throw version check error and halt deployment
- [ ] Ensure static content deploy is correctly deploying both secure and insecure versions of require js config file (preferably eliminate double runs here)
- [ ] Update README to reflect new minimum version requirement for Magento

## v0.7.1 Dev Checklist
- [ ] Enable production mode explicitly during deploy (because it was requested: davidalger/capistrano-magento2#68)
- [ ] Determine if "Deploying a new theme fails" can be resolved for 2.2.0-rc (davidalger/capistrano-magento2#63)
- [ ] Re-evaluate "Zero downtime on non-upgrade deployments" for 2.2.0-rc (davidalger/capistrano-magento2#34)
- [ ] Re-evaluate "Deploy shuts off maintenance mode" for 2.2.0-rc (davidalger/capistrano-magento2#16)