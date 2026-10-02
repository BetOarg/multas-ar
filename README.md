<div align="center">

# ⚖️ MULTAS AR 
 
**Asistente legal de infracciones de tránsito para Argentina**

Aplicación móvil multiplataforma (Android + iOS) para gestión profesional de reclamos y descargos de multas y fotomultas.

[![Status](https://img.shields.io/badge/status-en%20validaci%C3%B3n-yellow)]()
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-blue)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()

> ⚠️ **Aviso legal:** Esta aplicación es una herramienta de asistencia tecnológica. **No reemplaza el asesoramiento jurídico profesional** de un abogado/a matriculado/a.

</div>

---

## 📑 Tabla de contenidos

- [Estado del proyecto](#-estado-del-proyecto)
- [Filosofía](#-filosofía)
- [Stack tecnológico](#-stack-tecnológico)
- [Arquitectura del monorepo](#-arquitectura-del-monorepo)
- [Base normativa (congelada)](#-base-normativa-congelada)
- [Hoja de ruta](#-hoja-de-ruta)
- [Quick start](#-quick-start)
- [Convenciones](#-convenciones)
- [Documentación](#-documentación)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

---

## 🚦 Estado del proyecto

| Fase | Estado | Descripción |
|:---:|:---:|---|
| **Fase 0** | 🟡 En curso | Validación de mercado (20 entrevistas) |
| **Fase 1** | ⚪ Pendiente | MVP local (Flutter + Drift + OCR on-device) |
| **Fase 2** | ⚪ Pendiente | Multijurisdicción + publicación en stores |
| **Fase 3** | ⚪ Pendiente | Monetización + backend Supabase |
| **Fase 4** | ⚪ Pendiente | Escala (GCP + scrapers + API) |

**Criterio de continuidad:** si al final de Fase 1 no hay ≥5 usuarios activos semanales, el proyecto se detiene y se revisa el pivote.

---

## 🎯 Filosofía

El proyecto se rige por dos principios rectores:

### 🔒 Shared Kernel (congelado)

La **base de datos normativa** (jurisdicciones, plazos, prescripciones, feriados, taxonomía de nulidades, red flags, modelos de escritos) es **única, versionada y compartida**. Cualquier cambio pasa por revisión legal y afecta a ambos sistemas por igual.

### 🔓 Bounded Contexts (desacoplados)

Todo lo demás — UI, features, OCR, persistencia del usuario, generación de PDFs, sync remoto — vive en **paquetes independientes** que pueden extraerse a repos separados sin fricción si algún día Android e iOS se separan.

---

## 🛠 Stack tecnológico

| Capa | Tecnología | Razón |
|---|---|---|
| **Framework mobile** | Flutter 3.24+ | Un código, dos plataformas, rendimiento nativo |
| **Persistencia local** | Drift (SQLite) | ORM tipado, reactivo, multiplataforma |
| **OCR on-device** | Apple Vision (iOS) + ML Kit (Android) | Gratis, privado, rápido |
| **OCR fallback** | Tesseract | Último recurso multiplataforma |
| **Generación PDFs** | `pdf` package + Mustache | Estándar Flutter |
| **Estado global** | Riverpod | Recomendación 2025 |
| **Navegación** | go_router | Estándar actual |
| **Monorepo manager** | Melos | Estándar de facto en Flutter |
| **CI/CD** | GitHub Actions | Build automático por PR |
| **Analytics** | PostHog (Fase 3) | Open source, self-hostable |
| **Crash reporting** | Sentry (Fase 3) | Debug en producción |

**Backend:** sin backend en MVP. Todo local en Drift hasta Fase 3, donde se evalúa Supabase.

---

## 🏗 Arquitectura del monorepo

```
multas-ar/
├── melos.yaml                          # Gestor del monorepo
├── pubspec.yaml                        # Workspace raíz
│
├── packages/                           # ← Compartido entre Android e iOS
│   ├── legal_db/                       # 🔒 CONGELADO — base normativa
│   ├── core/                           # Entidades, value objects, Result
│   ├── domain/                         # Casos de uso, contratos
│   ├── data_local/                     # Drift (persistencia local)
│   ├── data_remote/                    # Supabase (Fase 3)
│   ├── ocr/                            # Adaptador OCR multiplataforma
│   ├── pdf_generator/                  # Generación de escritos
│   └── ui_kit/                         # Widgets compartidos
│
└── apps/
    └── mobile/                         # App Flutter (Android + iOS)
        ├── android/
        ├── ios/
        └── lib/
            ├── main.dart
            ├── app.dart
            ├── router/
            ├── features/
            └── di/
```

### Grafo de dependencias

```
core → legal_db → domain → data_local → ui_kit → apps/mobile
                                 ↓
                                ocr
                                 ↓
                            pdf_generator
```

**Regla de oro:** las flechas van en una sola dirección. `legal_db` nunca depende de `domain`. `core` nunca depende de Flutter.

### Responsabilidades por paquete

| Paquete | Rol | Extraíble |
|---|---|:---:|
| `legal_db` | Base normativa (frozen) | ✅ |
| `core` | Entidades, VO, Result | ✅ |
| `domain` | Casos de uso, contratos | ✅ |
| `data_local` | Drift (SQLite local) | ✅ |
| `data_remote` | Supabase sync (Fase 3) | ✅ |
| `ocr` | Adaptador OCR multiplataforma | ✅ |
| `pdf_generator` | Renderizado de escritos | ✅ |
| `ui_kit` | Widgets compartidos | ✅ |
| `apps/mobile` | Compositor final | — |

---

## 🔒 Base normativa (congelada)

La base normativa es la **fuente de verdad del proyecto**. Vive en `packages/legal_db/assets/` y no puede modificarse sin revisión legal.

### Jurisdicciones cubiertas (8)

| Jurisdicción | Norma principal | Prescripción | Caducidad fotomulta |
|---|---|---|---|
| **Nacional** | Ley 24.449 | 2 / 5 años | No establecido |
| **PBA** | Ley 13.927 + L. 15.002 | 2 / 5 años | 60 días hábiles |
| **CABA** | Ley 1217 (t.c. 6.764/2024) + L. 451 | 5 años (nominal) / 2 años (Andrade) | No aplica |
| **Río Negro** | Ley 5.263 | 2 / 5 años | 25 días hábiles |
| **Córdoba** | Ley 11.096/2025 | 2 / 5 años | Variable |
| **Santa Fe** | Ley 13.133 | 2 / 5 años | Variable |
| **Mendoza** | Ley 9024 | 2 / 3 / 4 años | Variable |
| **Neuquén** | Regulación local | 3 años | Variable |

### Modelos de escritos (9)

| ID | Modelo | Uso |
|:---:|---|---|
| A | Descargo PBA (JAITP) | 45 días hábiles desde notificación |
| B | Descargo CABA | 5 días hábiles desde notificación |
| C | Caducidad notificación fotomultas | PBA / Río Negro |
| D | Excepción prescripción | Juicio ejecutivo |
| E | Nulidad formal | Vicios del acta |
| F | Amparo fotomulta sin notificación | Vía excepcional |
| G | Amparo retención licencia | Arts. 72 / 72 bis L. 24.449 |
| H | Telegrama colacionado | Intimación |
| I | Recurso apelación PBA | 5 días hábiles (Art. 41) |

> Los textos legales completos de cada modelo viven en `packages/legal_db/assets/modelos_escritos.json`.

### Archivos clave

- `jurisdicciones.json` — 8 jurisdicciones con plazos, prescripciones, alertas duales
- `modelos_escritos.json` — 9 modelos con texto legal + campos obligatorios
- `taxonomia_nulidades.json` — 31 vicios (F/S/P/T)
- `red_flags.json` — 15+ códigos programables (RF-A01…RF-D04)
- `feriados_2026.json` — feriados nacionales, provinciales, judiciales
- `prescripciones.json` — reglas de interrupción (Art. 88/89)

---

## 🗺 Hoja de ruta

### Fase 0 — Validación (Semanas 1-4)

**Objetivo:** validar antes de construir.

| Semana | Actividad | Entregable |
|:---:|---|---|
| 1 | 10 entrevistas con abogados de tránsito | Notas crudas + patrones |
| 2 | 5 entrevistas con gestores/estudios | Notas crudas |
| 3 | Análisis competitivo (Multabot, gestores tradicionales) | Documento competitivo |
| 4 | Definir 1 caso de uso + pricing hipotético | One-pager |

**Go/no-go:** ≥5 de 15 entrevistados dicen "pagaría esto" o "lo usaría".

---

### Fase 1 — MVP funcional (Semanas 5-16)

**Objetivo:** prototipo real usable por 10 abogados.

**Alcance:**
- 1 jurisdicción (PBA)
- 3 modelos de escritos (A, C, D)
- OCR on-device (Apple Vision + ML Kit)
- Sin backend remoto (todo local en Drift)
- Sin autenticación (single-device)
- PDFs generables

| Semanas | Foco | Entregable |
|:---:|---|---|
| 5-6 | Setup monorepo + `legal_db` | 8 jurisdicciones + 3 modelos en JSON |
| 7-8 | `data_local` con Drift | Schema + migraciones + queries |
| 9-10 | `ocr` package | Factory + Apple Vision + ML Kit |
| 11 | UI análisis | Subir acta → ver análisis → alertas |
| 12 | Generación de PDFs | 3 modelos generables |
| 13-14 | Testing en 5 dispositivos | Bugs corregidos |
| 15-16 | Onboarding a 10 beta testers | Feedback estructurado |

**Go/no-go:** ≥5 usuarios activos semanales al final.

---

### Fase 2 — Multijurisdicción + publicación (Semanas 17-30)

| Semanas | Foco | Entregable |
|:---:|---|---|
| 17-20 | Completar 9 modelos | Modelos A-I con PDF |
| 21-24 | 8 jurisdicciones completas | Seed full + validación legal |
| 25-26 | Publicación Play Store | App en producción (Android) |
| 27-28 | Publicación App Store | App en producción (iOS) |
| 29-30 | Marketing inicial | 100 usuarios, primeras reseñas |

**Éxito:** ≥100 descargas orgánicas + ≥10 usuarios semanales + ≥3 pagos.

---

### Fase 3 — Monetización + Backend (Meses 8-12)

**Alcance:**
- Supabase (auth + sync + storage)
- Sistema de suscripciones (Google Play Billing + StoreKit)
- Freemium real
- Analytics (PostHog)
- Landing page + SEO

**Éxito:** ≥500 usuarios + ≥50 pagos + MRR ≥ $250.000 ARS.

---

### Fase 4 — Escala (Meses 13-18)

Solo si Fase 3 da resultados:
- Migración a GCP (Cloud SQL)
- Scrapers de normativa
- Integración con APIs de organismos
- API REST para estudios jurídicos
- Marca blanca para flotas

---

## 🚀 Quick start

### Prerrequisitos

- Flutter SDK 3.24+
- Dart 3.5+
- Melos (`dart pub global activate melos`)
- Xcode 15+ (para iOS)
- Android Studio Hedgehog+ (para Android)

### Setup

```bash
# Clonar
git clone https://github.com/tu-usuario/multas-ar.git
cd multas-ar

# Instalar Melos
dart pub global activate melos

# Bootstrap del monorepo
melos bootstrap

# Generar código de Drift
melos run gen:drift

# Correr tests
melos run test
```

### Desarrollo

```bash
# Android
cd apps/mobile && flutter run -d android

# iOS
cd apps/mobile && flutter run -d ios

# Ambos (con dispositivo conectado)
melos run dev
```

### Build de producción

```bash
# Android (AAB para Play Store)
melos run build:android

# iOS (IPA para App Store)
melos run build:ios
```

### CI/CD

Cada PR dispara:
- `flutter analyze`
- `flutter test`
- Build de debug (Android + iOS)

---

## 📐 Convenciones

### Código

- **Dart style:** `dart format` con 80 columnas
- **Linting:** `flutter_lints` + reglas custom en `analysis_options.yaml`
- **Naming:**
  - Paquetes: `snake_case`
  - Clases: `PascalCase`
  - Variables/funciones: `camelCase`
  - Constantes: `kCamelCase`
- **Arquitectura:** Clean Architecture por paquete
- **Estado:** Riverpod (providers por feature)
- **Errores:** `Result<T, E>` (no excepciones en dominio)

### Commits

Convención [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(ocr): add Apple Vision adapter
fix(drift): correct migration 2→3
docs(legal_db): update Córdoba jurisdiction
refactor(domain): extract plazos calculator
test(analisis): add edge cases for caducidad
```

### Branches

- `main` — producción
- `develop` — integración
- `feature/nombre` — features
- `fix/nombre` — bugfixes

### PRs

- Título en Conventional Commits
- Descripción: qué, por qué, cómo testear
- Al menos 1 reviewer
- Tests verdes obligatorios

---

## 📚 Documentación

| Documento | Ubicación | Descripción |
|---|---|---|
| Especificación técnica v2.0 | [`docs/SPEC.md`](docs/SPEC.md) | Documento maestro unificado |
| Base normativa | [`docs/NORMATIVA.md`](docs/NORMATIVA.md) | Jurisdicciones, plazos, prescripciones |
| Modelos de escritos | [`docs/MODELOS.md`](docs/MODELOS.md) | 9 plantillas legales |
| Arquitectura | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Monorepo + paquetes |
| Roadmap | [`docs/ROADMAP.md`](docs/ROADMAP.md) | Fases 0-4 con criterios go/no-go |
| Revisión técnica | [`docs/REVIEW.md`](docs/REVIEW.md) | Auditoría senior del stack |
| Contribuir | [`CONTRIBUTING.md`](CONTRIBUTING.md) | Guía de contribución |
| Código de conducta | [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Reglas de convivencia |

---

## 🤝 Contribuir

Las contribuciones son bienvenidas, especialmente:

- 🐛 **Reportes de bugs** — abrí un issue con reproducción
- 📚 **Actualizaciones normativas** — si una ley cambió, avisanos
- 🌍 **Nuevas jurisdicciones** — municipios, provincias faltantes
- 🌐 **Traducciones** — inglés, portugués (futuro)
- 📝 **Modelos de escritos** — plantillas adicionales validadas

**Antes de contribuir:**

1. Leé [CONTRIBUTING.md](CONTRIBUTING.md)
2. Revisá issues abiertos para no duplicar
3. Para cambios normativos, adjuntá fuente oficial (Boletín Oficial, etc.)
4. Para cambios legales en modelos, adjuntá validación de abogado/a

> ⚠️ **Los cambios a `packages/legal_db` requieren revisión legal obligatoria.**

---

## ⚠️ Advertencias legales

### Para usuarios

Esta aplicación es una **herramienta de asistencia tecnológica**. No constituye asesoramiento jurídico profesional, no crea relación abogado-cliente, y no reemplaza la consulta con un profesional matriculado.

Los análisis, plazos y escritos generados son **orientativos** y deben ser verificados con la normativa vigente y un abogado/a antes de su presentación ante cualquier autoridad.

### Para contribuidores

- No agregues jurisprudencia sin verificar la fuente oficial.
- No modifiques plazos sin adjuntar cita legal.
- No inventes artículos, leyes o fallos.
- Si tenés dudas, marcá el dato como "⚠️ verificar" en lugar de afirmarlo.

---

## 📄 Licencia

MIT © 2026 — ver [LICENSE](LICENSE)

El uso del código es libre. El uso de la base normativa (`packages/legal_db/assets/`) es libre con atribución. Los textos legales de los modelos de escritos son de dominio público (fuentes oficiales).

---

## 🙏 Agradecimientos

- Comunidad Flutter Argentina
- Abogados que participaron en validación (Fase 0)
- Contribuidores de repos open source usados (Drift, Riverpod, go_router)

---

<div align="center">

**¿Preguntas?** Abrí un [issue](https://github.com/tu-usuario/multas-ar/issues) o escribí a `contacto@multas-ar.app`

Hecho con ⚖️ en Argentina

</div>
