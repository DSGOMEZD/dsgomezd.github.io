// Site-wide configuration
export const siteConfig = {
  // Site metadata
  name: "Portafolio Santiago",
  title: "Portafolio Santiago",
  description: "",
  
  // Navigation
  navigation: {
    home: "Presentacion",
    posts: "Contenido",
    contact: "Contacto",
  },
  
  // Hero Section
  hero: {
    prefix: "yo soy",
    name: "David Santiago Gomez Duran",
    intro: "Soy un estudiante de ingenieria de sistemas, Actualmente Estudio en la universidad del bosque, voy en 4 semestre y este es mi portafolio de evidencias y contenido para Bases de Datos II",
    avatar: "/image/Foto Santiago.jpg",
    buttons: {
      viewPosts: "Ver Contenido",
      contactMe: "Contactame",
    },
    socialLinks: [
      { name: "Instagram", icon: "/svg/instagram.svg", url: "https://www.instagram.com/g0mez_santiag0_07?igsh=MWNuaXdhd3AxNWYycA==" },
      { name: "Facebook", icon: "/svg/facebook.svg", url: "https://www.facebook.com/share/1FM5BzYkyx/" },
      { name: "GitHub", icon: "/svg/github.svg", url: "https://github.com/DSGOMEZD/dsgomezd.github.io" },
    ],
  },
  
  // About Section
  about: {
    title: "Video Presentacion",
    
  },
  
  // Contact Page
  contact: {
    title: "Pongase en contacto",
    subtitle: "Siempre estoy abierto a discutir nuevos proyectos, ideas creativas u oportunidades para ser parte de tus visiones.",
    info: {
      email: {
        label: "Email",
        value: "dsgomezd@unbosque.edu.co",
      },
      phone: {
        label: "Phone",
        value: "301-1158556",
    
      },
      location: {
        label: "Location",
        value: "Bogota, Colombia",
      },
    },
    followMe: {
      title: "Sigueme",
      links: [
        { name: "Instagram", icon: "/svg/instagram.svg", url: "https://www.instagram.com/g0mez_santiag0_07?igsh=MWNuaXdhd3AxNWYycA==" },
      { name: "Facebook", icon: "/svg/facebook.svg", url: "https://www.facebook.com/share/1FM5BzYkyx/" },
      { name: "GitHub", icon: "/svg/github.svg", url: "https://github.com/DSGOMEZD/dsgomezd.github.io" },
      ],
    },
    footerText: [
      "I typically respond to messages within 24 hours during business days.",
      "Looking forward to hearing from you! 🚀",
    ],
    
  },
  
  // Footer
  footer: {
    copyright: "© 2025 Someone. All rights reserved.",
    links: [
      { text: "Privacy Policy", url: "#" },
      { text: "Terms of Service", url: "#" },
      { text: "Sitemap", url: "#" },
    ],
    github: {
      text: "Star this project on Github",
      url: "https://github.com/tomcomtang/astro-cartoon-portfolio",
    },
  },
  
  // Posts Page
  posts: {
    title: "Contenido",
    subtitle: "Contenido Bases de Datos II",
    searchPlaceholder: "Buscar Evidencia...",
  },
  
  // Comments Page
  comments: {
    title: "Comments & Discussion",
    subtitle: "Share your thoughts, questions, or suggestions here. Let's connect and discuss!",
    guidelines: {
      title: "Community Guidelines",
      items: [
        "Be respectful and constructive in your comments",
        "No spam, self-promotion, or advertising allowed",
        "No personal attacks, hate speech, or harassment",
        "Stay on topic and keep discussions relevant",
        "No inappropriate, offensive, or illegal content",
        "Use clear, friendly, and inclusive language",
      ],
    },
  },
};

