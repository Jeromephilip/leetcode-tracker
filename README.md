# LeetCode Tracker

A comprehensive web application that helps developers track their LeetCode progress, manage problem-solving statistics, and integrate with LeetCode's platform through a Chrome extension.

## Features

### Core Functionality
- **User Authentication**: Secure user registration and login using Devise
- **LeetCode Integration**: Connect your LeetCode account to track progress
- **Progress Dashboard**: Visual representation of your problem-solving journey
- **Statistics Tracking**: Monitor your performance across different difficulty levels
- **Chrome Extension**: Seamless integration with LeetCode's website

### Technical Features
- **Rails Backend**: Built with Ruby on Rails for robust API endpoints
- **Database Management**: Comprehensive user data and statistics storage
- **API Integration**: RESTful API for LeetCode data synchronization
- **Responsive Design**: Modern, mobile-friendly user interface

## Tech Stack

- **Backend**: Ruby on Rails 7
- **Database**: SQLite (development), PostgreSQL (production ready)
- **Authentication**: Devise gem
- **Frontend**: ERB templates with modern CSS
- **Testing**: Minitest framework
- **Background Jobs**: Sidekiq for async processing

## Prerequisites

Before running this application, make sure you have:

- Ruby 3.0+ installed
- Rails 7.0+ installed
- Node.js and Yarn (for asset compilation)
- Git

## Installation

1. **Clone the repository**
   ```bash
   git clone git@github.com:Jeromephilip/leetcode-tracker.git
   cd leetcode-tracker
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start the server**
   ```bash
   rails server
   ```

5. **Install Chrome Extension**
   - Navigate to `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select the `public/chrome-extension/` folder

## Configuration

### Environment Variables
Create a `.env` file in the root directory:

```bash
# LeetCode API Configuration
LEETCODE_API_URL=https://leetcode.com/api
LEETCODE_SESSION_TOKEN=your_session_token_here

# Database Configuration
DATABASE_URL=your_database_url_here

# Application Configuration
SECRET_KEY_BASE=your_secret_key_here
```

### Database Configuration
The application uses SQLite by default for development. For production, update `config/database.yml` with your PostgreSQL credentials.

## Usage

### Web Application
1. Visit `http://localhost:3000` in your browser
2. Sign up for a new account or log in
3. Connect your LeetCode account in the dashboard
4. View your progress and statistics

### Chrome Extension
1. Navigate to any LeetCode problem page
2. The extension will automatically detect the page
3. Click the extension icon to sync your progress
4. View real-time updates in your dashboard

## Database Schema

### Users Table
- Basic user information (email, password)
- LeetCode username and authentication tokens
- Problem-solving statistics and progress tracking

### Migrations
- `devise_create_users`: User authentication setup
- `add_leetcode_fields_to_users`: LeetCode integration fields
- `add_leet_code_stats_to_users`: Statistics tracking
- `fix_duplicate_leetcode_usernames`: Data integrity fixes

## Testing

Run the test suite with:

```bash
rails test
```

Or run specific test files:

```bash
rails test test/models/user_test.rb
rails test test/controllers/dashboard_controller_test.rb
```

## Deployment

### Heroku
1. Create a new Heroku app
2. Add PostgreSQL addon
3. Set environment variables
4. Deploy with `git push heroku main`

### Docker
1. Build the image: `docker build -t leetcode-tracker .`
2. Run the container: `docker run -p 3000:3000 leetcode-tracker`

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -am 'Add feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [LeetCode](https://leetcode.com/) for providing the problem-solving platform
- [Devise](https://github.com/heartcombo/devise) for authentication
- [Ruby on Rails](https://rubyonrails.org/) community for the amazing framework

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/Jeromephilip/leetcode-tracker/issues) page
2. Create a new issue with detailed information
3. Contact the maintainers

---

**Happy Coding!**

*Track your LeetCode progress, improve your skills, and build amazing applications.*
