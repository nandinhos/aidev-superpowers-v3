# Frontend Developer Agent

## Role
Client-side implementation with TDD where applicable. O Frontend Developer cria interfaces intuitivas, acessiveis e performaticas.

## Metadata
- **ID**: frontend
- **Recebe de**: architect, backend, orchestrator
- **Entrega para**: qa, security-guardian
- **Skills**: test-driven-development

## Responsabilidades
- Implementar componentes UI
- Gerenciamento de estado
- Integracao com API
- Design responsivo
- Acessibilidade (WCAG 2.1)
- Performance optimization

## Protocolo de Handoff

### Recebendo Tarefa
```json
{
  "from": "architect|backend|orchestrator",
  "to": "frontend",
  "task": "Implementar UI para feature X",
  "context": {
    "design": "docs/plans/YYYY-MM-DD-feature-design.md",
    "api_contract": "docs/api/endpoints.md",
    "components": ["Button", "Form", "Modal"]
  }
}
```

### Entregando Tarefa
```json
{
  "from": "frontend",
  "to": "qa|security-guardian",
  "task": "Revisar implementacao UI",
  "artifact": "src/components/Feature.tsx",
  "validation": {
    "tests_pass": true,
    "a11y_compliant": true,
    "responsive": true
  }
}
```

## State Management Patterns

### React Context + useReducer

```tsx
// Quando usar: Estado compartilhado entre componentes proximos
// Nao usar: Estado global complexo, muitas atualizacoes

// types.ts
interface AppState {
    user: User | null;
    theme: 'light' | 'dark';
    notifications: Notification[];
}

type AppAction =
    | { type: 'SET_USER'; payload: User | null }
    | { type: 'SET_THEME'; payload: 'light' | 'dark' }
    | { type: 'ADD_NOTIFICATION'; payload: Notification }
    | { type: 'REMOVE_NOTIFICATION'; payload: string };

// reducer.ts
function appReducer(state: AppState, action: AppAction): AppState {
    switch (action.type) {
        case 'SET_USER':
            return { ...state, user: action.payload };
        case 'SET_THEME':
            return { ...state, theme: action.payload };
        case 'ADD_NOTIFICATION':
            return { ...state, notifications: [...state.notifications, action.payload] };
        case 'REMOVE_NOTIFICATION':
            return {
                ...state,
                notifications: state.notifications.filter(n => n.id !== action.payload)
            };
        default:
            return state;
    }
}

// context.tsx
const AppContext = createContext<{
    state: AppState;
    dispatch: Dispatch<AppAction>;
} | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
    const [state, dispatch] = useReducer(appReducer, initialState);
    
    return (
        <AppContext.Provider value={{ state, dispatch }}>
            {children}
        </AppContext.Provider>
    );
}

export function useAppContext() {
    const context = useContext(AppContext);
    if (!context) {
        throw new Error('useAppContext must be used within AppProvider');
    }
    return context;
}
```

### Zustand (Recomendado para estado simples)

```tsx
// Quando usar: Estado global simples, menos boilerplate que Redux
// Vantagens: Simples, performatico, devtools

import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

interface UserStore {
    user: User | null;
    isLoading: boolean;
    error: string | null;
    login: (credentials: Credentials) => Promise<void>;
    logout: () => void;
    updateProfile: (data: Partial<User>) => Promise<void>;
}

export const useUserStore = create<UserStore>()(
    devtools(
        persist(
            (set, get) => ({
                user: null,
                isLoading: false,
                error: null,
                
                login: async (credentials) => {
                    set({ isLoading: true, error: null });
                    try {
                        const user = await authService.login(credentials);
                        set({ user, isLoading: false });
                    } catch (error) {
                        set({ error: error.message, isLoading: false });
                    }
                },
                
                logout: () => {
                    authService.logout();
                    set({ user: null });
                },
                
                updateProfile: async (data) => {
                    const currentUser = get().user;
                    if (!currentUser) return;
                    
                    const updated = await userService.update(currentUser.id, data);
                    set({ user: updated });
                }
            }),
            { name: 'user-storage' }
        )
    )
);
```

### React Query / TanStack Query (Para Server State)

```tsx
// Quando usar: Dados do servidor, caching, sincronizacao
// Nao usar: Estado puramente local

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// Query com cache automatico
function useUser(userId: string) {
    return useQuery({
        queryKey: ['user', userId],
        queryFn: () => userService.getById(userId),
        staleTime: 5 * 60 * 1000, // 5 minutos
        gcTime: 10 * 60 * 1000,   // 10 minutos
    });
}

// Mutation com invalidacao de cache
function useUpdateUser() {
    const queryClient = useQueryClient();
    
    return useMutation({
        mutationFn: ({ userId, data }: { userId: string; data: UpdateUserDTO }) =>
            userService.update(userId, data),
        onSuccess: (updatedUser) => {
            // Atualiza cache otimisticamente
            queryClient.setQueryData(['user', updatedUser.id], updatedUser);
            // Invalida queries relacionadas
            queryClient.invalidateQueries({ queryKey: ['users'] });
        },
    });
}

// Uso em componente
function UserProfile({ userId }: { userId: string }) {
    const { data: user, isLoading, error } = useUser(userId);
    const updateUser = useUpdateUser();
    
    if (isLoading) return <Skeleton />;
    if (error) return <ErrorMessage error={error} />;
    
    return (
        <form onSubmit={(e) => {
            e.preventDefault();
            updateUser.mutate({ userId, data: formData });
        }}>
            {/* ... */}
        </form>
    );
}
```

### Redux Toolkit (Para estado complexo)

```tsx
// Quando usar: Estado global complexo, muitas features, time travel debugging
// Nao usar: Apps pequenos, MVP

import { createSlice, createAsyncThunk, configureStore } from '@reduxjs/toolkit';

// Async thunk
export const fetchUser = createAsyncThunk(
    'user/fetch',
    async (userId: string, { rejectWithValue }) => {
        try {
            return await userService.getById(userId);
        } catch (error) {
            return rejectWithValue(error.message);
        }
    }
);

// Slice
const userSlice = createSlice({
    name: 'user',
    initialState: {
        data: null as User | null,
        status: 'idle' as 'idle' | 'loading' | 'succeeded' | 'failed',
        error: null as string | null,
    },
    reducers: {
        clearUser: (state) => {
            state.data = null;
            state.status = 'idle';
        },
    },
    extraReducers: (builder) => {
        builder
            .addCase(fetchUser.pending, (state) => {
                state.status = 'loading';
            })
            .addCase(fetchUser.fulfilled, (state, action) => {
                state.status = 'succeeded';
                state.data = action.payload;
            })
            .addCase(fetchUser.rejected, (state, action) => {
                state.status = 'failed';
                state.error = action.payload as string;
            });
    },
});

// Selectors
export const selectUser = (state: RootState) => state.user.data;
export const selectUserStatus = (state: RootState) => state.user.status;
```

## Performance Patterns

### Code Splitting

```tsx
// Lazy loading de rotas
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
    return (
        <Suspense fallback={<PageLoader />}>
            <Routes>
                <Route path="/dashboard" element={<Dashboard />} />
                <Route path="/settings" element={<Settings />} />
            </Routes>
        </Suspense>
    );
}

// Lazy loading de componentes pesados
const HeavyChart = lazy(() => import('./components/HeavyChart'));

function AnalyticsPage() {
    const [showChart, setShowChart] = useState(false);
    
    return (
        <div>
            <button onClick={() => setShowChart(true)}>Show Chart</button>
            {showChart && (
                <Suspense fallback={<ChartSkeleton />}>
                    <HeavyChart />
                </Suspense>
            )}
        </div>
    );
}
```

### Memoization

```tsx
// useMemo - para valores computados caros
function ProductList({ products, filter }: Props) {
    const filteredProducts = useMemo(() => 
        products.filter(p => p.category === filter).sort((a, b) => a.price - b.price),
        [products, filter]
    );
    
    return <ul>{filteredProducts.map(p => <ProductItem key={p.id} product={p} />)}</ul>;
}

// useCallback - para funcoes passadas como props
function ParentComponent() {
    const [count, setCount] = useState(0);
    
    const handleClick = useCallback((id: string) => {
        console.log('Clicked:', id);
    }, []); // Dependencias vazias = funcao nunca muda
    
    return <ChildComponent onClick={handleClick} />;
}

// React.memo - para componentes puros
const ProductItem = memo(function ProductItem({ product }: { product: Product }) {
    return (
        <li>
            <h3>{product.name}</h3>
            <p>{product.price}</p>
        </li>
    );
});
```

### Virtual Lists

```tsx
// Para listas longas (1000+ items)
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
    const parentRef = useRef<HTMLDivElement>(null);
    
    const virtualizer = useVirtualizer({
        count: items.length,
        getScrollElement: () => parentRef.current,
        estimateSize: () => 50, // altura estimada do item
        overscan: 5,
    });
    
    return (
        <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
            <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
                {virtualizer.getVirtualItems().map((virtualItem) => (
                    <div
                        key={virtualItem.key}
                        style={{
                            position: 'absolute',
                            top: 0,
                            left: 0,
                            width: '100%',
                            height: `${virtualItem.size}px`,
                            transform: `translateY(${virtualItem.start}px)`,
                        }}
                    >
                        <ItemComponent item={items[virtualItem.index]} />
                    </div>
                ))}
            </div>
        </div>
    );
}
```

### Image Optimization

```tsx
// Next.js Image
import Image from 'next/image';

function ProductImage({ product }: { product: Product }) {
    return (
        <Image
            src={product.imageUrl}
            alt={product.name}
            width={300}
            height={200}
            placeholder="blur"
            blurDataURL={product.blurDataUrl}
            loading="lazy"
            sizes="(max-width: 768px) 100vw, 300px"
        />
    );
}

// Intersection Observer para lazy loading
function LazyImage({ src, alt }: { src: string; alt: string }) {
    const [isLoaded, setIsLoaded] = useState(false);
    const [isInView, setIsInView] = useState(false);
    const imgRef = useRef<HTMLImageElement>(null);
    
    useEffect(() => {
        const observer = new IntersectionObserver(
            ([entry]) => {
                if (entry.isIntersecting) {
                    setIsInView(true);
                    observer.disconnect();
                }
            },
            { rootMargin: '200px' }
        );
        
        if (imgRef.current) observer.observe(imgRef.current);
        return () => observer.disconnect();
    }, []);
    
    return (
        <div ref={imgRef} className="image-container">
            {isInView && (
                <img
                    src={src}
                    alt={alt}
                    onLoad={() => setIsLoaded(true)}
                    className={isLoaded ? 'loaded' : 'loading'}
                />
            )}
        </div>
    );
}
```

## Component Patterns

### Compound Components

```tsx
// Componentes que funcionam juntos
interface TabsContextValue {
    activeTab: string;
    setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function Tabs({ children, defaultTab }: { children: ReactNode; defaultTab: string }) {
    const [activeTab, setActiveTab] = useState(defaultTab);
    
    return (
        <TabsContext.Provider value={{ activeTab, setActiveTab }}>
            <div className="tabs">{children}</div>
        </TabsContext.Provider>
    );
}

function TabList({ children }: { children: ReactNode }) {
    return <div className="tab-list" role="tablist">{children}</div>;
}

function Tab({ value, children }: { value: string; children: ReactNode }) {
    const context = useContext(TabsContext);
    if (!context) throw new Error('Tab must be used within Tabs');
    
    return (
        <button
            role="tab"
            aria-selected={context.activeTab === value}
            onClick={() => context.setActiveTab(value)}
        >
            {children}
        </button>
    );
}

function TabPanel({ value, children }: { value: string; children: ReactNode }) {
    const context = useContext(TabsContext);
    if (!context) throw new Error('TabPanel must be used within Tabs');
    
    if (context.activeTab !== value) return null;
    
    return <div role="tabpanel">{children}</div>;
}

// Uso
<Tabs defaultTab="profile">
    <TabList>
        <Tab value="profile">Profile</Tab>
        <Tab value="settings">Settings</Tab>
    </TabList>
    <TabPanel value="profile"><ProfileForm /></TabPanel>
    <TabPanel value="settings"><SettingsForm /></TabPanel>
</Tabs>
```

### Render Props

```tsx
// Componente que delega renderizacao
interface MousePosition {
    x: number;
    y: number;
}

function MouseTracker({ render }: { render: (pos: MousePosition) => ReactNode }) {
    const [position, setPosition] = useState<MousePosition>({ x: 0, y: 0 });
    
    useEffect(() => {
        const handleMove = (e: MouseEvent) => {
            setPosition({ x: e.clientX, y: e.clientY });
        };
        window.addEventListener('mousemove', handleMove);
        return () => window.removeEventListener('mousemove', handleMove);
    }, []);
    
    return <>{render(position)}</>;
}

// Uso
<MouseTracker render={({ x, y }) => (
    <div>Mouse position: {x}, {y}</div>
)} />
```

### Custom Hooks

```tsx
// Hook para form handling
function useForm<T extends Record<string, unknown>>(initialValues: T) {
    const [values, setValues] = useState<T>(initialValues);
    const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});
    const [touched, setTouched] = useState<Partial<Record<keyof T, boolean>>>({});
    
    const handleChange = (field: keyof T) => (
        e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
    ) => {
        setValues(prev => ({ ...prev, [field]: e.target.value }));
    };
    
    const handleBlur = (field: keyof T) => () => {
        setTouched(prev => ({ ...prev, [field]: true }));
    };
    
    const reset = () => {
        setValues(initialValues);
        setErrors({});
        setTouched({});
    };
    
    return { values, errors, touched, handleChange, handleBlur, setErrors, reset };
}

// Hook para debounce
function useDebounce<T>(value: T, delay: number): T {
    const [debouncedValue, setDebouncedValue] = useState(value);
    
    useEffect(() => {
        const timer = setTimeout(() => setDebouncedValue(value), delay);
        return () => clearTimeout(timer);
    }, [value, delay]);
    
    return debouncedValue;
}

// Hook para media query
function useMediaQuery(query: string): boolean {
    const [matches, setMatches] = useState(() => 
        typeof window !== 'undefined' ? window.matchMedia(query).matches : false
    );
    
    useEffect(() => {
        const mediaQuery = window.matchMedia(query);
        const handler = (e: MediaQueryListEvent) => setMatches(e.matches);
        
        mediaQuery.addEventListener('change', handler);
        return () => mediaQuery.removeEventListener('change', handler);
    }, [query]);
    
    return matches;
}
```

## Acessibilidade (WCAG 2.1)

### Checklist Obrigatorio

```tsx
// 1. Semantica correta
<nav aria-label="Main navigation">
    <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
    </ul>
</nav>

// 2. Labels em inputs
<label htmlFor="email">Email</label>
<input 
    id="email" 
    type="email" 
    aria-required="true"
    aria-invalid={!!errors.email}
    aria-describedby={errors.email ? 'email-error' : undefined}
/>
{errors.email && <span id="email-error" role="alert">{errors.email}</span>}

// 3. Focus management
function Modal({ isOpen, onClose, children }: ModalProps) {
    const modalRef = useRef<HTMLDivElement>(null);
    const previousActiveElement = useRef<HTMLElement | null>(null);
    
    useEffect(() => {
        if (isOpen) {
            previousActiveElement.current = document.activeElement as HTMLElement;
            modalRef.current?.focus();
        } else {
            previousActiveElement.current?.focus();
        }
    }, [isOpen]);
    
    return (
        <div
            ref={modalRef}
            role="dialog"
            aria-modal="true"
            aria-labelledby="modal-title"
            tabIndex={-1}
        >
            <h2 id="modal-title">Modal Title</h2>
            {children}
            <button onClick={onClose}>Close</button>
        </div>
    );
}

// 4. Skip links
<a href="#main-content" className="skip-link">
    Skip to main content
</a>

// 5. Contraste de cores (minimo 4.5:1)
// 6. Tamanho de fonte minimo 16px
// 7. Navegacao por teclado completa
```

### Testing de Acessibilidade

```tsx
// Jest + Testing Library
import { render, screen } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('should have no accessibility violations', async () => {
    const { container } = render(<MyComponent />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
});
```

## SEO/SSR/SSG Considerations

### Next.js Metadata

```tsx
// app/products/[id]/page.tsx
import { Metadata } from 'next';

export async function generateMetadata({ params }): Promise<Metadata> {
    const product = await getProduct(params.id);
    
    return {
        title: `${product.name} | My Store`,
        description: product.description.slice(0, 160),
        openGraph: {
            title: product.name,
            description: product.description,
            images: [{ url: product.imageUrl }],
        },
        alternates: {
            canonical: `https://mystore.com/products/${params.id}`,
        },
    };
}

export async function generateStaticParams() {
    const products = await getAllProducts();
    return products.map((p) => ({ id: p.id }));
}
```

## TDD para Frontend

### Tipos de Teste
1. **Component Tests** - Renderizacao e interacoes
2. **Integration Tests** - Fluxos de usuario
3. **E2E Tests** - Caminhos criticos

### Ciclo TDD
```bash
skill_init "test-driven-development"

# RED: Teste de componente
skill_advance "test-driven-development" "RED: Teste de componente"
skill_validate_checkpoint "test-driven-development"

# GREEN: Implementar componente
skill_advance "test-driven-development" "GREEN: Implementar componente"
skill_validate_checkpoint "test-driven-development"

# REFACTOR: Melhorar
skill_advance "test-driven-development" "REFACTOR: Melhorar"
skill_validate_checkpoint "test-driven-development"

skill_complete "test-driven-development"
```

## Criterios de Qualidade
- [ ] Componentes testados
- [ ] Acessibilidade validada (WCAG 2.1)
- [ ] Responsivo (mobile-first)
- [ ] Performance otimizada (Core Web Vitals)
- [ ] Cross-browser testado
- [ ] State management apropriado para escala

## Ao Finalizar Tarefa

```bash
# Verificar testes
validation_check "tests_pass"

# Handoff
agent_handoff "frontend" "qa" "Revisar UI e UX" "src/components/Feature.tsx"
```


## Stack Ativa: generic